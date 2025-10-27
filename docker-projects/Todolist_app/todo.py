import json
import os

TODO_FILE = '/data/todos.json'

def load_todos():
    if os.path.exists(TODO_FILE):
        with open(TODO_FILE, 'r') as f:
            return json.load(f)
    return []

def save_todos(todos):
    os.makedirs(os.path.dirname(TODO_FILE), exist_ok=True)
    with open(TODO_FILE, 'w') as f:
        json.dump(todos, f, indent=2)

def show_todos(todos):
    if not todos:
        print("\nNo todos yet!")
        return
    
    print("\n📝 Your Todos:")
    for i, todo in enumerate(todos, 1):
        status = "✓" if todo['done'] else " "
        print(f"{i}. [{status}] {todo['task']}")

def main():
    todos = load_todos()
    
    while True:
        print("\n--- Todo List ---")
        print("1. Show todos")
        print("2. Add todo")
        print("3. Mark done")
        print("4. Delete todo")
        print("5. Exit")
        
        choice = input("\nChoice: ")
        
        if choice == '1':
            show_todos(todos)
        
        elif choice == '2':
            task = input("Enter task: ")
            todos.append({'task': task, 'done': False})
            save_todos(todos)
            print("✓ Added!")
        
        elif choice == '3':
            show_todos(todos)
            try:
                num = int(input("Mark which number done? "))
                todos[num-1]['done'] = True
                save_todos(todos)
                print("✓ Marked done!")
            except (ValueError, IndexError):
                print("Invalid number!")
        
        elif choice == '4':
            show_todos(todos)
            try:
                num = int(input("Delete which number? "))
                todos.pop(num-1)
                save_todos(todos)
                print("✓ Deleted!")
            except (ValueError, IndexError):
                print("Invalid number!")
        
        elif choice == '5':
            print("Goodbye!")
            break

if __name__ == '__main__':
    main()