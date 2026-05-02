// ========================================
// Task Manager - JavaScript
// ========================================

const API_BASE_URL = '/tasks';

// DOM Elements
const taskForm = document.getElementById('taskForm');
const taskTitleInput = document.getElementById('taskTitle');
const taskList = document.getElementById('taskList');
const taskCount = document.getElementById('taskCount');
const loading = document.getElementById('loading');
const errorMessage = document.getElementById('errorMessage');
const emptyState = document.getElementById('emptyState');

// ========================================
// API Functions
// ========================================

/**
 * Fetch all tasks from the backend
 */
async function fetchTasks() {
    showLoading();
    hideError();
    
    try {
        const response = await fetch(API_BASE_URL);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const tasks = await response.json();
        renderTasks(tasks);
    } catch (error) {
        console.error('Error fetching tasks:', error);
        showError('Failed to load tasks. Please make sure the backend is running.');
        hideTaskList();
    } finally {
        hideLoading();
    }
}

/**
 * Create a new task
 */
async function createTask(title) {
    hideError();
    
    try {
        const response = await fetch(API_BASE_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ title: title }),
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const task = await response.json();
        addTaskToList(task);
        updateTaskCount();
        clearInput();
        
        // Show success feedback
        showTemporaryMessage('Task added successfully!', 'success');
    } catch (error) {
        console.error('Error creating task:', error);
        showError('Failed to create task. Please try again.');
    }
}

/**
 * Delete a task
 */
async function deleteTask(id) {
    hideError();
    
    try {
        const response = await fetch(`${API_BASE_URL}/${id}`, {
            method: 'DELETE',
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        removeTaskFromList(id);
        updateTaskCount();
        
        // Show success feedback
        showTemporaryMessage('Task deleted successfully!', 'success');
    } catch (error) {
        console.error('Error deleting task:', error);
        showError('Failed to delete task. Please try again.');
    }
}

// ========================================
// UI Functions
// ========================================

/**
 * Render all tasks to the DOM
 */
function renderTasks(tasks) {
    taskList.innerHTML = '';
    
    if (tasks.length === 0) {
        showEmptyState();
        return;
    }
    
    hideEmptyState();
    showTaskList();
    
    tasks.forEach(task => {
        const taskElement = createTaskElement(task);
        taskList.appendChild(taskElement);
    });
    
    updateTaskCount();
}

/**
 * Create a task list item element
 */
function createTaskElement(task) {
    const li = document.createElement('li');
    li.className = 'task-item';
    li.id = `task-${task.id}`;
    
    const statusClass = task.status === 'COMPLETED' ? 'status-completed' : 'status-pending';
    
    li.innerHTML = `
        <div class="task-info">
            <span class="task-id">#${task.id}</span>
            <span class="task-title">${escapeHtml(task.title)}</span>
            <span class="task-status ${statusClass}">${task.status}</span>
        </div>
        <div class="task-actions">
            <button class="btn btn-danger" onclick="handleDelete(${task.id})">
                🗑️ Delete
            </button>
        </div>
    `;
    
    return li;
}

/**
 * Add a single task to the list
 */
function addTaskToList(task) {
    hideEmptyState();
    showTaskList();
    
    const taskElement = createTaskElement(task);
    taskList.appendChild(taskElement);
}

/**
 * Remove a task from the list
 */
function removeTaskFromList(id) {
    const taskElement = document.getElementById(`task-${id}`);
    if (taskElement) {
        taskElement.style.animation = 'fadeOut 0.3s ease';
        setTimeout(() => {
            taskElement.remove();
            // Check if list is empty
            if (taskList.children.length === 0) {
                showEmptyState();
            }
        }, 300);
    }
}

/**
 * Update the task count display
 */
function updateTaskCount() {
    const count = taskList.children.length;
    taskCount.textContent = `${count} task${count !== 1 ? 's' : ''}`;
}

/**
 * Clear the input field
 */
function clearInput() {
    taskTitleInput.value = '';
    taskTitleInput.focus();
}

// ========================================
// Event Handlers
// ========================================

/**
 * Handle form submission
 */
taskForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const title = taskTitleInput.value.trim();
    
    if (!title) {
        showError('Please enter a task title.');
        return;
    }
    
    await createTask(title);
});

/**
 * Handle delete button click
 */
async function handleDelete(id) {
    if (confirm('Are you sure you want to delete this task?')) {
        await deleteTask(id);
    }
}

// ========================================
// Utility Functions
// ========================================

/**
 * Escape HTML to prevent XSS
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

/**
 * Show loading state
 */
function showLoading() {
    loading.classList.remove('hidden');
    taskList.classList.add('hidden');
    emptyState.classList.add('hidden');
}

/**
 * Hide loading state
 */
function hideLoading() {
    loading.classList.add('hidden');
}

/**
 * Show task list
 */
function showTaskList() {
    taskList.classList.remove('hidden');
}

/**
 * Hide task list
 */
function hideTaskList() {
    taskList.classList.add('hidden');
}

/**
 * Show empty state
 */
function showEmptyState() {
    emptyState.classList.remove('hidden');
    taskList.classList.add('hidden');
}

/**
 * Hide empty state
 */
function hideEmptyState() {
    emptyState.classList.add('hidden');
}

/**
 * Show error message
 */
function showError(message) {
    errorMessage.textContent = message;
    errorMessage.classList.remove('hidden');
}

/**
 * Hide error message
 */
function hideError() {
    errorMessage.classList.add('hidden');
}

/**
 * Show temporary message
 */
function showTemporaryMessage(message, type = 'info') {
    const messageDiv = document.createElement('div');
    messageDiv.className = `message message-${type}`;
    messageDiv.textContent = message;
    messageDiv.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 1rem 1.5rem;
        background-color: ${type === 'success' ? '#28a745' : '#4a90d9'};
        color: white;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        z-index: 1000;
        animation: slideIn 0.3s ease;
    `;
    
    document.body.appendChild(messageDiv);
    
    setTimeout(() => {
        messageDiv.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => {
            document.body.removeChild(messageDiv);
        }, 300);
    }, 3000);
}

// Add animation keyframes
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            opacity: 0;
            transform: translateX(100px);
        }
        to {
            opacity: 1;
            transform: translateX(0);
        }
    }
    
    @keyframes slideOut {
        from {
            opacity: 1;
            transform: translateX(0);
        }
        to {
            opacity: 0;
            transform: translateX(100px);
        }
    }
    
    @keyframes fadeOut {
        from {
            opacity: 1;
            transform: translateY(0);
        }
        to {
            opacity: 0;
            transform: translateY(-10px);
        }
    }
`;
document.head.appendChild(style);

// ========================================
// Initialize
// ========================================

// Load tasks when page loads
document.addEventListener('DOMContentLoaded', () => {
    fetchTasks();
});