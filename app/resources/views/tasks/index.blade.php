<x-app-layout>
    <div class="max-w-xl mx-auto p-6">

        <h1 class="text-2xl font-bold mb-4">Task Manager</h1>

        <!-- Add Task -->
        <form method="POST" action="{{ route('tasks.store') }}" class="flex gap-2">
            @csrf
            <input 
                type="text" 
                name="title" 
                placeholder="New task..." 
                class="border p-2 w-full rounded"
                required
            >
            <button class="bg-blue-500 text-white px-4 py-2 rounded">
                Add
            </button>
        </form>

        <!-- Task List -->
        <ul class="mt-6 space-y-2">
            @foreach($tasks as $task)
                <li class="flex justify-between items-center bg-white p-3 shadow rounded">
                    <span>{{ $task->title }}</span>

                    <form method="POST" action="{{ route('tasks.destroy', $task) }}">
                        @csrf
                        @method('DELETE')
                        <button class="text-red-500 hover:text-red-700">
                            Delete
                        </button>
                    </form>
                </li>
            @endforeach
        </ul>

    </div>
</x-app-layout>