from flask import Flask, render_template, request, redirect, url_for, jsonify
import json
import os

app = Flask(__name__)

TODO_FILE = '/app/data/todos.json'  # where we save todos (/app/data is volume mount point)


# CATEGORY AND PRIORITY MANAGEMENT

def auto_assign_category(task):
    """Automatically assign category based on task keywords"""
    task_lower = task.lower()

    # Docker-related keywords
    if any(word in task_lower for word in ['docker', 'watchtower', 'wud', 'container']):
        return 'Docker'

    # HomeAssistant-related keywords
    if any(word in task_lower for word in ['homeassistant', 'home assistant', 'hacs', 'watchman', 'vscode extension']):
        return 'HomeAssistant'

    # Remote Access keywords
    if any(word in task_lower for word in ['remote', 'ssh', 'vpn', 'tailscale', 'access']):
        return 'Remote Access'

    # Scripting keywords
    if any(word in task_lower for word in ['script', 'api', 'flask', 'scriptable', 'cloud', 'sync']):
        return 'Scripting'

    # Monitoring keywords
    if any(word in task_lower for word in ['monitor', 'water', 'tracking', 'phpipam', 'phipam']):
        return 'Monitoring'

    # Default category
    return 'General'


def migrate_todos(todos):
    """Migrate old todos to new format with category and priority"""
    migrated = False
    for todo in todos:
        # Add category if missing
        if 'category' not in todo:
            todo['category'] = auto_assign_category(todo['task'])
            migrated = True

        # Add priority if missing (default to Medium)
        if 'priority' not in todo:
            todo['priority'] = 'Medium'
            migrated = True

    return todos, migrated


def calculate_metrics(todos):
    """Calculate metrics for the dashboard"""
    total_tasks = len(todos)
    pending_tasks = sum(1 for todo in todos if not todo['done'])
    completed_tasks = sum(1 for todo in todos if todo['done'])
    completion_percentage = (completed_tasks / total_tasks * 100) if total_tasks > 0 else 0
    high_priority_pending = sum(1 for todo in todos if not todo['done'] and todo.get('priority') == 'High')

    return {
        'total': total_tasks,
        'pending': pending_tasks,
        'completed': completed_tasks,
        'completion_percentage': round(completion_percentage, 1),
        'high_priority_pending': high_priority_pending
    }


#  Check to see if JSON file exists, if yes -> read and convert JSON to python list, if not -> empty string
def load_todos():
    """Load todos from JSON file and migrate if needed"""
    if os.path.exists(TODO_FILE):           # Does file exist?
        with open(TODO_FILE, 'r') as f:     # Open file for reading
            todos = json.load(f)            # Parse JSON -> Python list

        # Migrate old todos to new format with category/priority
        todos, migrated = migrate_todos(todos)
        if migrated:
            save_todos(todos)               # Save if migration occurred

        return todos
    return []                               # if no file, return empty list

# Make sure /data exists, Convert Python lisy to JSON, Writes files with pretty formatting
def save_todos(todos):
    """Save todos to JSON file"""
    os.makedirs(os.path.dirname(TODO_FILE), exist_ok=True)  # create /data if needed
    with open(TODO_FILE, 'w') as f:                         # Open for writing
        json.dump(todos, f, indent=2)                       # Convert list -> JSON


# ROUTES

# when someone visits localhost:5000/ -> Flask calls index() fx, Loads todos from JSON,
# calculates metrics, groups by category, and renders the page
@app.route('/')     # @ = decorator, '/' tells flask, when someone visits /, run this fx
def index():
    """Main page - shows all todos with metrics and category grouping"""
    todos = load_todos()                                # get todos from file
    metrics = calculate_metrics(todos)                  # calculate dashboard metrics

    # Group todos by category
    categories = ['Docker', 'HomeAssistant', 'Remote Access', 'Scripting', 'Monitoring', 'General']
    grouped_todos = {}
    for category in categories:
        category_todos = [todo for todo in todos if todo.get('category') == category]
        if category_todos:  # Only include categories that have todos
            grouped_todos[category] = category_todos

    return render_template('index.html',
                         todos=todos,
                         metrics=metrics,
                         grouped_todos=grouped_todos)


# User types task, selects category/priority & clicks add -> browser sends POST request to /add
# flask gets form data and creates new todo dictionary with all fields
@app.route('/add', methods=['POST'])
def add_todo():
    """Add a new todo with category and priority"""
    task = request.form.get('task')             # Get text from form input
    category = request.form.get('category', 'General')  # Get category (default: General)
    priority = request.form.get('priority', 'Medium')   # Get priority (default: Medium)

    if task:                                    # If they typed something
        todos = load_todos()                    # Load existing todos
        todos.append({                          # Add new todo to list
            'task': task,
            'done': False,
            'id': len(todos),                   # ID = current length
            'category': category,
            'priority': priority
        })
        save_todos(todos)                       # Save updated list
    return redirect(url_for('index'))           # Go back to homepage

#You click "Done" button for todo, Browser goes to /toggle/2,
# Flask calls toggle_todo(2) - the 2 becomes todo_id, Gets todo at index 2: todos[2]
# Flips done: False → True (or vice versa), Saves and redirects
@app.route('/toggle/<int:todo_id>')
def toggle_todo(todo_id):
    """Mark a todo as done/undone"""
    todos = load_todos()                          # Load todos
    if 0 <= todo_id < len(todos):                 # Valid ID?
        todos[todo_id]['done'] = not todos[todo_id]['done']  # Flip True↔False
        save_todos(todos)                         # Save
    return redirect(url_for('index'))             # Back to homepage


# Update priority of a todo
@app.route('/update_priority/<int:todo_id>', methods=['POST'])
def update_priority(todo_id):
    """Update the priority of a todo"""
    priority = request.form.get('priority')       # Get new priority from form
    if priority in ['High', 'Medium', 'Low']:     # Valid priority?
        todos = load_todos()                      # Load todos
        if 0 <= todo_id < len(todos):             # Valid ID?
            todos[todo_id]['priority'] = priority # Update priority
            save_todos(todos)                     # Save
    return redirect(url_for('index'))             # Back to homepage


# Click "Delete" on todo -> Goes to /delete/ -> Removes todo at index 1: todos.pop(1)
# Reassigns IDs so they're sequential again, Saves and redirects
@app.route('/delete/<int:todo_id>')
def delete_todo(todo_id):
    """Delete a todo"""
    todos = load_todos()                    # Load todos
    if 0 <= todo_id < len(todos):           # Valid ID?
        todos.pop(todo_id)                  # Remove from list
        for i, todo in enumerate(todos):    # Loop through remaining
            todo['id'] = i                  # Reassign IDs (0, 1, 2...)
        save_todos(todos)                   # Save
    return redirect(url_for('index'))       # Back to homepage


# API ENDPOINTS (for Scriptable widget and other apps)

@app.route('/api/todos', methods=['GET'])
def api_get_todos():
    """API endpoint to get all todos as JSON"""
    todos = load_todos()                    # Load todos from file
    return jsonify(todos), 200              # Return as JSON with 200 OK status


@app.route('/api/todos/<int:todo_id>', methods=['GET'])
def api_get_todo(todo_id):
    """API endpoint to get a single todo as JSON"""
    todos = load_todos()                    # Load todos
    if 0 <= todo_id < len(todos):           # Valid ID?
        return jsonify(todos[todo_id]), 200 # Return that todo as JSON
    return jsonify({'error': 'Todo not found'}), 404  # Not found error


@app.route('/api/todos', methods=['POST'])
def api_add_todo():
    """API endpoint to create a new todo with category and priority"""
    data = request.get_json()               # Get JSON data from request
    if not data or 'task' not in data:      # Check if task was provided
        return jsonify({'error': 'Task is required'}), 400

    todos = load_todos()                    # Load existing todos
    new_todo = {
        'task': data['task'],
        'done': data.get('done', False),    # Default to not done
        'id': len(todos),
        'category': data.get('category', 'General'),    # Default to General
        'priority': data.get('priority', 'Medium')      # Default to Medium
    }
    todos.append(new_todo)                  # Add to list
    save_todos(todos)                       # Save
    return jsonify(new_todo), 201           # Return new todo with 201 Created


@app.route('/api/todos/<int:todo_id>', methods=['PUT', 'PATCH'])
def api_update_todo(todo_id):
    """API endpoint to update a todo (including category and priority)"""
    todos = load_todos()                    # Load todos
    if not (0 <= todo_id < len(todos)):     # Valid ID?
        return jsonify({'error': 'Todo not found'}), 404

    data = request.get_json()               # Get update data
    if 'task' in data:                      # Update task if provided
        todos[todo_id]['task'] = data['task']
    if 'done' in data:                      # Update done status if provided
        todos[todo_id]['done'] = data['done']
    if 'category' in data:                  # Update category if provided
        todos[todo_id]['category'] = data['category']
    if 'priority' in data:                  # Update priority if provided
        todos[todo_id]['priority'] = data['priority']

    save_todos(todos)                       # Save changes
    return jsonify(todos[todo_id]), 200     # Return updated todo


@app.route('/api/todos/<int:todo_id>', methods=['DELETE'])
def api_delete_todo(todo_id):
    """API endpoint to delete a todo"""
    todos = load_todos()                    # Load todos
    if not (0 <= todo_id < len(todos)):     # Valid ID?
        return jsonify({'error': 'Todo not found'}), 404

    deleted_todo = todos.pop(todo_id)       # Remove todo
    for i, todo in enumerate(todos):        # Reassign IDs
        todo['id'] = i
    save_todos(todos)                       # Save
    return jsonify({'message': 'Todo deleted', 'todo': deleted_todo}), 200


# Run Server
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
