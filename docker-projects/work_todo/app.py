from flask import Flask, render_template, request, redirect, url_for, jsonify
import json
import os

app = Flask(__name__)

TODO_FILE  = '/app/data/todos.json'
STATS_FILE = '/app/data/stats.json'

VALID_CATEGORIES = ['Projects', 'Planning', 'Meetings/Follow-ups', 'Documentation', 'Research', 'General']


# STATS PERSISTENCE

def load_stats():
    if os.path.exists(STATS_FILE):
        with open(STATS_FILE, 'r') as f:
            return json.load(f)
    return {'deleted_done_count': 0}


def save_stats(stats):
    os.makedirs(os.path.dirname(STATS_FILE), exist_ok=True)
    with open(STATS_FILE, 'w') as f:
        json.dump(stats, f, indent=2)


# CATEGORY AND PRIORITY MANAGEMENT

def auto_assign_category(task):
    task_lower = task.lower()

    if any(w in task_lower for w in ['project', 'initiative', 'milestone', 'deliverable', 'epic', 'feature']):
        return 'Projects'

    if any(w in task_lower for w in ['plan', 'planning', 'roadmap', 'sprint', 'backlog', 'scope', 'jira', 'ticket']):
        return 'Planning'

    if any(w in task_lower for w in ['meeting', 'follow up', 'follow-up', 'action item', 'standup', 'sync', 'call', 'email', 'reply', 'respond', 'schedule']):
        return 'Meetings/Follow-ups'

    if any(w in task_lower for w in ['doc', 'documentation', 'write', 'readme', 'wiki', 'confluence', 'report', 'deck', 'slides', 'presentation']):
        return 'Documentation'

    if any(w in task_lower for w in ['research', 'investigate', 'explore', 'look into', 'evaluate', 'poc', 'proof of concept', 'prototype']):
        return 'Research'

    return 'General'


def migrate_todos(todos):
    migrated = False
    for todo in todos:
        if 'category' not in todo:
            todo['category'] = auto_assign_category(todo['task'])
            migrated = True
        if 'priority' not in todo:
            todo['priority'] = 'Medium'
            migrated = True
        if 'notes' not in todo:
            todo['notes'] = ''
            migrated = True
    return todos, migrated


def calculate_metrics(todos, stats=None):
    if stats is None:
        stats = {'deleted_done_count': 0}

    deleted_done      = stats.get('deleted_done_count', 0)
    current_done      = sum(1 for t in todos if t['done'])
    current_pending   = sum(1 for t in todos if not t['done'])
    completed_tasks   = current_done + deleted_done
    total_tasks       = len(todos) + deleted_done
    completion_pct    = (completed_tasks / total_tasks * 100) if total_tasks > 0 else 0
    high_priority     = sum(1 for t in todos if not t['done'] and t.get('priority') == 'High')

    return {
        'total': total_tasks,
        'pending': current_pending,
        'completed': completed_tasks,
        'completion_percentage': round(completion_pct, 1),
        'high_priority_pending': high_priority
    }


# FILE I/O

def load_todos():
    if os.path.exists(TODO_FILE):
        with open(TODO_FILE, 'r') as f:
            todos = json.load(f)
        todos, migrated = migrate_todos(todos)
        if migrated:
            save_todos(todos)
        return todos
    return []


def save_todos(todos):
    os.makedirs(os.path.dirname(TODO_FILE), exist_ok=True)
    with open(TODO_FILE, 'w') as f:
        json.dump(todos, f, indent=2)


# ROUTES

@app.route('/')
def index():
    todos    = load_todos()
    stats    = load_stats()
    metrics  = calculate_metrics(todos, stats)
    sort     = request.args.get('sort', 'category')

    def sink_done(items):
        """Keep original order but push completed tasks to the bottom."""
        return sorted(items, key=lambda t: t['done'])

    grouped_todos = {}
    if sort == 'urgency':
        for priority in ['High', 'Medium', 'Low']:
            priority_todos = [t for t in todos if t.get('priority') == priority]
            if priority_todos:
                grouped_todos[priority] = sink_done(priority_todos)
    else:
        for category in VALID_CATEGORIES:
            category_todos = [t for t in todos if t.get('category') == category]
            if category_todos:
                grouped_todos[category] = sink_done(category_todos)

    return render_template('index.html',
                           todos=todos,
                           metrics=metrics,
                           grouped_todos=grouped_todos,
                           sort=sort,
                           categories=VALID_CATEGORIES)


@app.route('/add', methods=['POST'])
def add_todo():
    task     = request.form.get('task')
    category = request.form.get('category', 'General')
    priority = request.form.get('priority', 'Medium')

    if task:
        todos = load_todos()
        todos.append({
            'task': task,
            'done': False,
            'id': len(todos),
            'category': category,
            'priority': priority,
            'notes': ''
        })
        save_todos(todos)
    return redirect(url_for('index'))


@app.route('/toggle/<int:todo_id>')
def toggle_todo(todo_id):
    todos = load_todos()
    if 0 <= todo_id < len(todos):
        todos[todo_id]['done'] = not todos[todo_id]['done']
        save_todos(todos)
    return redirect(url_for('index'))


@app.route('/update_priority/<int:todo_id>', methods=['POST'])
def update_priority(todo_id):
    priority = request.form.get('priority')
    sort     = request.form.get('sort', 'category')
    if priority in ['High', 'Medium', 'Low']:
        todos = load_todos()
        if 0 <= todo_id < len(todos):
            todos[todo_id]['priority'] = priority
            save_todos(todos)
    return redirect(url_for('index', sort=sort))


@app.route('/update_category/<int:todo_id>', methods=['POST'])
def update_category(todo_id):
    category = request.form.get('category')
    sort     = request.form.get('sort', 'category')
    if category in VALID_CATEGORIES:
        todos = load_todos()
        if 0 <= todo_id < len(todos):
            todos[todo_id]['category'] = category
            save_todos(todos)
    return redirect(url_for('index', sort=sort))


@app.route('/update_notes/<int:todo_id>', methods=['POST'])
def update_notes(todo_id):
    notes = request.form.get('notes', '').strip()
    sort  = request.form.get('sort', 'category')
    todos = load_todos()
    if 0 <= todo_id < len(todos):
        todos[todo_id]['notes'] = notes
        save_todos(todos)
    return redirect(url_for('index', sort=sort))


@app.route('/delete/<int:todo_id>')
def delete_todo(todo_id):
    todos = load_todos()
    if 0 <= todo_id < len(todos):
        removed = todos.pop(todo_id)
        if removed.get('done', False):
            stats = load_stats()
            stats['deleted_done_count'] = stats.get('deleted_done_count', 0) + 1
            save_stats(stats)
        for i, todo in enumerate(todos):
            todo['id'] = i
        save_todos(todos)
    return redirect(url_for('index'))


# API ENDPOINTS

@app.route('/api/todos', methods=['GET'])
def api_get_todos():
    return jsonify(load_todos()), 200


@app.route('/api/todos/<int:todo_id>', methods=['GET'])
def api_get_todo(todo_id):
    todos = load_todos()
    if 0 <= todo_id < len(todos):
        return jsonify(todos[todo_id]), 200
    return jsonify({'error': 'Todo not found'}), 404


@app.route('/api/todos', methods=['POST'])
def api_add_todo():
    data = request.get_json()
    if not data or 'task' not in data:
        return jsonify({'error': 'Task is required'}), 400

    todos    = load_todos()
    new_todo = {
        'task':     data['task'],
        'done':     data.get('done', False),
        'id':       len(todos),
        'category': data.get('category', 'General'),
        'priority': data.get('priority', 'Medium'),
        'notes':    data.get('notes', '')
    }
    todos.append(new_todo)
    save_todos(todos)
    return jsonify(new_todo), 201


@app.route('/api/todos/<int:todo_id>', methods=['PUT', 'PATCH'])
def api_update_todo(todo_id):
    todos = load_todos()
    if not (0 <= todo_id < len(todos)):
        return jsonify({'error': 'Todo not found'}), 404

    data = request.get_json()
    for field in ('task', 'done', 'category', 'priority', 'notes'):
        if field in data:
            todos[todo_id][field] = data[field]

    save_todos(todos)
    return jsonify(todos[todo_id]), 200


@app.route('/api/todos/<int:todo_id>', methods=['DELETE'])
def api_delete_todo(todo_id):
    todos = load_todos()
    if not (0 <= todo_id < len(todos)):
        return jsonify({'error': 'Todo not found'}), 404

    deleted_todo = todos.pop(todo_id)
    if deleted_todo.get('done', False):
        stats = load_stats()
        stats['deleted_done_count'] = stats.get('deleted_done_count', 0) + 1
        save_stats(stats)
    for i, todo in enumerate(todos):
        todo['id'] = i
    save_todos(todos)
    return jsonify({'message': 'Todo deleted', 'todo': deleted_todo}), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
