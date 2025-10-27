from flask import Flask, render_template, request, redirect, url_for
import json
import os

app = Flask(__name__)

TODO_FILE = '/data/todos.json'  # where we save todos (/data is volume mount point)


#  Check to see if JSON file exists, if yes -> read and convert JSON to python list, if not -> empty string
def load_todos():
    """Load todos from JSON file"""
    if os.path.exists(TODO_FILE):           # Does file exist?
        with open(TODO_FILE, 'r') as f:     # Open file for reading
            return json.load(f)             # Parse JSON -> Python list
    return []                               # if no file, return empty list

# Make sure /data exists, Convert Python lisy to JSON, Writes files with pretty formatting
def save_todos(todos):
    """Save todos to JSON file"""
    os.makedirs(os.path.dirname(TODO_FILE), exist_ok=True)  # create /data if needed
    with open(TODO_FILE, 'w') as f:                         # Open for writing
        json.dump(todos, f, indent=2)                       # Convert list -> JSON


# ROUTES

# when someone visits localhost:5000/ -> Flask calls index() fx, Loads todos from JSON, 
# rendeers index.html and passes todos to it, sends html back to browser
@app.route('/')     # @ = decorator, '/' tells flask, when someone visits /, run this fx
def index():
    """Main page - shows all todos"""
    todos = load_todos()                                # get todos from file
    return render_template('index.html', todos=todos)   # show html with todos


# User types 'buy milk' & clicks add -> browser send POST request to /add -> 
# flask gets text 'task = 'buy milk' -> creates new todo dictionary
@app.route('/add', methods=['POST'])
def add_todo():
    """Add a new todo"""
    task = request.form.get('task')    # Get text from form input
    if task:                            # If they typed something
        todos = load_todos()            # Load existing todos
        todos.append({                  # Add new todo to list
            'task': task,
            'done': False,
            'id': len(todos)            # ID = current length
        })
        save_todos(todos)               # Save updated list
    return redirect(url_for('index'))   # Go back to homepage

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


# Run Server
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
