/**
 * StudyFlow Tracker - Interactive Client Application
 */

// Initial Seed State
const DEFAULT_SUBJECTS = [
  { id: 'sub_1', name: 'Mathematics & Calculus', color: '#6366f1', targetWeeklyHours: 5 },
  { id: 'sub_2', name: 'Computer Science & DSA', color: '#06b6d4', targetWeeklyHours: 7 },
  { id: 'sub_3', name: 'Physics & Engineering', color: '#8b5cf6', targetWeeklyHours: 4 },
  { id: 'sub_4', name: 'Language & Literature', color: '#10b981', targetWeeklyHours: 3 },
];

const DEFAULT_SCHEDULES = [
  {
    id: 'sch_1',
    subjectId: 'sub_2',
    title: 'Algorithms & LeetCode Practice',
    description: 'Graph algorithms (BFS, DFS, Dijkstra) and dynamic programming.',
    startTime: '09:00',
    endTime: '10:30',
    days: [1, 2, 3, 4, 5], // Mon-Fri
    reminderMins: 10,
    isEnabled: true
  },
  {
    id: 'sch_2',
    subjectId: 'sub_1',
    title: 'Linear Algebra & Calculus Drill',
    description: 'Eigenvalues, Vector Spaces, Matrix operations and proofs.',
    startTime: '17:00',
    endTime: '18:30',
    days: [1, 3, 5], // Mon, Wed, Fri
    reminderMins: 15,
    isEnabled: true
  },
  {
    id: 'sch_3',
    subjectId: 'sub_3',
    title: 'Quantum Mechanics & Modern Physics',
    description: 'Wave-particle duality and Schrödinger equation review.',
    startTime: '20:00',
    endTime: '21:15',
    days: [2, 4, 6],
    reminderMins: 10,
    isEnabled: true
  }
];

const DEFAULT_NOTES = [
  {
    id: 'note_1',
    subjectId: 'sub_2',
    scheduleId: 'sch_1',
    title: 'BFS vs DFS Traversal Patterns',
    content: `### Summary of Key Findings:
- **BFS (Breadth-First Search)**: Uses a Queue (FIFO). Essential for finding shortest path in unweighted graphs.
- **DFS (Depth-First Search)**: Uses recursion/stack (LIFO). Best for connected components, topological sorting, and cycle detection.

\`\`\`python
def bfs(graph, start):
    visited = {start}
    queue = [start]
    while queue:
        vertex = queue.pop(0)
        for neighbor in graph[vertex]:
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)
\`\`\`
`,
    checklist: [
      { id: 'c1', text: 'Implement iterative BFS in Python/Dart', isDone: true },
      { id: 'c2', text: 'Solve LeetCode #200 (Number of Islands)', isDone: true },
      { id: 'c3', text: 'Review Dijkstra algorithm edge cases', isDone: false },
    ],
    tags: ['algorithms', 'graphs', 'interview'],
    createdAt: new Date(Date.now() - 3600000 * 4).toISOString()
  }
];

// App State
let state = {
  subjects: JSON.parse(localStorage.getItem('sf_subjects')) || DEFAULT_SUBJECTS,
  schedules: JSON.parse(localStorage.getItem('sf_schedules')) || DEFAULT_SCHEDULES,
  sessions: JSON.parse(localStorage.getItem('sf_sessions')) || [
    {
      id: 'sess_1',
      subjectId: 'sub_2',
      durationMinutes: 45,
      date: new Date().toISOString()
    },
    {
      id: 'sess_2',
      subjectId: 'sub_1',
      durationMinutes: 60,
      date: new Date(Date.now() - 86400000).toISOString()
    }
  ],
  notes: JSON.parse(localStorage.getItem('sf_notes')) || DEFAULT_NOTES,
  soundEnabled: JSON.parse(localStorage.getItem('sf_sound') ?? 'true'),
  dayFilter: 0, // 0 = all
  timer: {
    mode: 'pomodoro', // 'pomodoro' | 'custom'
    phase: 'work', // 'work' | 'shortBreak' | 'longBreak'
    totalSeconds: 25 * 60,
    remainingSeconds: 25 * 60,
    isRunning: false,
    intervalId: null,
    completedCycles: 0,
    selectedSubjectId: null,
    activeScheduleId: null,
    sessionStartTime: null,
  }
};

// Save helper
function persistState() {
  localStorage.setItem('sf_subjects', JSON.stringify(state.subjects));
  localStorage.setItem('sf_schedules', JSON.stringify(state.schedules));
  localStorage.setItem('sf_sessions', JSON.stringify(state.sessions));
  localStorage.setItem('sf_notes', JSON.stringify(state.notes));
  localStorage.setItem('sf_sound', JSON.stringify(state.soundEnabled));
}

// ==========================================
// Web Audio API Sound Synthesizer
// ==========================================
const audioCtx = new (window.AudioContext || window.webkitAudioContext)();

function playTone(freq = 587.33, type = 'sine', duration = 0.5, delay = 0) {
  if (!state.soundEnabled) return;
  setTimeout(() => {
    try {
      if (audioCtx.state === 'suspended') audioCtx.resume();
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = type;
      osc.frequency.setValueAtTime(freq, audioCtx.currentTime);
      gain.gain.setValueAtTime(0.2, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + duration);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start();
      osc.stop(audioCtx.currentTime + duration);
    } catch (e) {
      console.warn('Audio error:', e);
    }
  }, delay * 1000);
}

function playStudyStartChime() {
  playTone(523.25, 'sine', 0.3, 0.0); // C5
  playTone(659.25, 'sine', 0.3, 0.15); // E5
  playTone(783.99, 'sine', 0.5, 0.3); // G5
}

function playStudyAlarmBell() {
  // Rich bell chord
  playTone(880, 'sine', 0.8, 0.0); // A5
  playTone(1046.5, 'sine', 0.8, 0.1); // C6
  playTone(1318.5, 'triangle', 1.0, 0.2); // E6
  playTone(880, 'sine', 0.8, 0.6);
}

function playBreakChime() {
  playTone(783.99, 'sine', 0.3, 0.0); // G5
  playTone(659.25, 'sine', 0.3, 0.15); // E5
  playTone(523.25, 'sine', 0.5, 0.3); // C5
}

// ==========================================
// Desktop Notifications API
// ==========================================
function checkNotificationPermission() {
  if (!('Notification' in window)) return;
  const banner = document.getElementById('notif-permission-banner');
  if (Notification.permission === 'default') {
    banner.classList.remove('hidden');
  } else {
    banner.classList.add('hidden');
  }
}

function requestNotificationPermission() {
  if ('Notification' in window) {
    Notification.requestPermission().then(permission => {
      checkNotificationPermission();
      if (permission === 'granted') {
        showDesktopNotification('🎉 Notifications Enabled!', 'You will receive timely reminders before your study sessions start.');
      }
    });
  }
}

function showDesktopNotification(title, body) {
  playStudyAlarmBell();
  if ('Notification' in window && Notification.permission === 'granted') {
    new Notification(title, {
      body: body,
      icon: 'https://cdn-icons-png.fl127.net/512/3233/3233483.png',
    });
  }
}

// Background scheduler checker for study alarms
setInterval(() => {
  const now = new Date();
  const currentDay = now.getDay() === 0 ? 7 : now.getDay(); // 1=Mon .. 7=Sun
  const currentHour = now.getHours();
  const currentMinute = now.getMinutes();

  state.schedules.forEach(sch => {
    if (!sch.isEnabled || !sch.days.includes(currentDay)) return;
    const [startH, startM] = sch.startTime.split(':').map(Number);
    
    // Calculate trigger time subtracting reminderMins
    let alertMinute = startM - sch.reminderMins;
    let alertHour = startH;
    if (alertMinute < 0) {
      alertMinute += 60;
      alertHour -= 1;
    }

    if (currentHour === alertHour && currentMinute === alertMinute && now.getSeconds() < 3) {
      const subject = state.subjects.find(s => s.id === sch.subjectId);
      const subjectName = subject ? subject.name : 'Study Session';
      const reminderText = sch.reminderMins > 0 ? `starts in ${sch.reminderMins} minutes` : 'is starting now!';
      showDesktopNotification(`📚 Study Time: ${sch.title}`, `[${subjectName}] ${reminderText}. Time to focus!`);
    }
  });
}, 5000);

// ==========================================
// Tab Switching
// ==========================================
function switchTab(tabId) {
  document.querySelectorAll('.tab-content').forEach(el => el.classList.add('hidden'));
  document.querySelectorAll('.nav-btn').forEach(el => {
    el.classList.remove('active', 'text-indigo-400');
    el.classList.add('text-slate-400');
  });

  const activeContent = document.getElementById(`tab-${tabId}`);
  if (activeContent) activeContent.classList.remove('hidden');

  const activeBtn = document.querySelector(`.nav-btn[data-target="${tabId}"]`);
  if (activeBtn) {
    activeBtn.classList.add('active', 'text-indigo-400');
    activeBtn.classList.remove('text-slate-400');
  }

  if (tabId === 'analytics') {
    renderAnalytics();
  }
  lucide.createIcons();
}

// ==========================================
// UI Rendering
// ==========================================
function formatTime12(time24) {
  if (!time24) return '';
  const [h, m] = time24.split(':').map(Number);
  const ampm = h >= 12 ? 'PM' : 'AM';
  const hour12 = h % 12 || 12;
  return `${hour12.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')} ${ampm}`;
}

function getDurationMinutes(startStr, endStr) {
  const [h1, m1] = startStr.split(':').map(Number);
  const [h2, m2] = endStr.split(':').map(Number);
  let diff = (h2 * 60 + m2) - (h1 * 60 + m1);
  if (diff <= 0) diff += 24 * 60;
  return diff;
}

function renderDashboard() {
  // Stats
  const today = new Date().toISOString().slice(0, 10);
  const todayMinutes = state.sessions
    .filter(s => s.date.startsWith(today))
    .reduce((sum, s) => sum + s.durationMinutes, 0);

  document.getElementById('stat-today-time').innerText = todayMinutes >= 60
    ? `${Math.floor(todayMinutes / 60)}h ${todayMinutes % 60}m`
    : `${todayMinutes}m`;

  const currentDay = new Date().getDay() === 0 ? 7 : new Date().getDay();
  const todaySchedules = state.schedules.filter(s => s.days.includes(currentDay));
  document.getElementById('stat-today-schedules').innerText = todaySchedules.length;
  document.getElementById('stat-total-notes').innerText = state.notes.length;

  // Next Upcoming schedule
  const nextSch = todaySchedules.find(s => s.isEnabled) || state.schedules.find(s => s.isEnabled);
  if (nextSch) {
    document.getElementById('upcoming-title').innerText = nextSch.title;
    const dur = getDurationMinutes(nextSch.startTime, nextSch.endTime);
    document.getElementById('upcoming-time').innerText = `${formatTime12(nextSch.startTime)} - ${formatTime12(nextSch.endTime)} (${dur} mins) • Alarm ${nextSch.reminderMins}m before`;
    document.getElementById('upcoming-start-btn').onclick = () => {
      startSessionFromSchedule(nextSch);
    };
  }

  // Dashboard schedules list
  const dashList = document.getElementById('dashboard-schedules-list');
  if (todaySchedules.length === 0) {
    dashList.innerHTML = `<div class="p-6 bg-slate-800/40 rounded-2xl text-center text-slate-500 text-xs">No study schedules set for today!</div>`;
  } else {
    dashList.innerHTML = todaySchedules.map(sch => createScheduleCardHTML(sch, true)).join('');
  }

  // Dashboard notes list
  const notesList = document.getElementById('dashboard-notes-list');
  if (state.notes.length === 0) {
    notesList.innerHTML = `<div class="p-6 bg-slate-800/40 rounded-2xl text-center text-slate-500 text-xs">No notes yet. Create your first study note!</div>`;
  } else {
    notesList.innerHTML = state.notes.slice(0, 3).map(n => createNoteCardHTML(n, true)).join('');
  }

  lucide.createIcons();
}

function createScheduleCardHTML(sch, isCompact = false) {
  const subject = state.subjects.find(s => s.id === sch.subjectId) || { name: 'General', color: '#6366f1' };
  const dur = getDurationMinutes(sch.startTime, sch.endTime);
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  const daysPills = dayNames.map((name, i) => {
    const isSelected = sch.days.includes(i + 1);
    return `<span class="px-1.5 py-0.5 rounded text-[10px] font-semibold ${isSelected ? 'bg-indigo-600 text-white' : 'bg-slate-800 text-slate-500'}">${name[0]}</span>`;
  }).join('');

  return `
    <div class="bg-slate-800/90 border border-slate-700/80 rounded-2xl p-4 transition hover:border-slate-600">
      <div class="flex items-center justify-between gap-2 mb-2">
        <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold" style="background-color: ${subject.color}20; color: ${subject.color}; border: 1px solid ${subject.color}40;">
          <span class="w-2 h-2 rounded-full" style="background-color: ${subject.color}"></span>
          ${subject.name}
        </span>
        <div class="flex items-center gap-2">
          <span class="text-[11px] text-amber-400 bg-amber-400/10 px-2 py-0.5 rounded-full border border-amber-400/20 flex items-center gap-1">
            <i data-lucide="bell" class="w-3 h-3"></i> ${sch.reminderMins}m before
          </span>
          <button onclick="toggleScheduleActive('${sch.id}')" class="p-1 text-slate-400 hover:text-white" title="${sch.isEnabled ? 'Active' : 'Muted'}">
            <i data-lucide="${sch.isEnabled ? 'toggle-right' : 'toggle-left'}" class="w-5 h-5 ${sch.isEnabled ? 'text-indigo-400' : 'text-slate-600'}"></i>
          </button>
        </div>
      </div>

      <h3 class="text-sm font-bold text-white">${sch.title}</h3>
      ${sch.description ? `<p class="text-xs text-slate-400 mt-1 line-clamp-1">${sch.description}</p>` : ''}

      <div class="flex items-center gap-2 mt-3 text-xs text-slate-300 font-medium">
        <i data-lucide="clock" class="w-3.5 h-3.5 text-indigo-400"></i>
        <span>${formatTime12(sch.startTime)} - ${formatTime12(sch.endTime)}</span>
        <span class="text-slate-500">(${dur} mins)</span>
      </div>

      <div class="flex items-center gap-1 mt-3">
        ${daysPills}
      </div>

      <div class="flex items-center gap-2 mt-4 pt-3 border-t border-slate-700/60">
        <button onclick="startSessionFromScheduleById('${sch.id}')" class="flex-1 bg-indigo-600 hover:bg-indigo-500 text-white py-1.5 rounded-xl text-xs font-semibold flex items-center justify-center gap-1.5 shadow-md shadow-indigo-600/20">
          <i data-lucide="play" class="w-3.5 h-3.5 fill-white"></i> Start Focus
        </button>
        <button onclick="openNoteModalForSchedule('${sch.id}')" class="bg-slate-700 hover:bg-slate-600 text-slate-200 px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-1">
          <i data-lucide="file-plus" class="w-3.5 h-3.5"></i> Note
        </button>
        <button onclick="editSchedule('${sch.id}')" class="p-1.5 text-slate-400 hover:text-white rounded-lg hover:bg-slate-700">
          <i data-lucide="edit-3" class="w-4 h-4"></i>
        </button>
      </div>
    </div>
  `;
}

function createNoteCardHTML(note, isCompact = false) {
  const subject = state.subjects.find(s => s.id === note.subjectId) || { name: 'General', color: '#6366f1' };
  const doneChecklist = (note.checklist || []).filter(c => c.isDone).length;
  const totalChecklist = (note.checklist || []).length;
  const parsedMarkdown = marked.parse(note.content || '');

  const dateFormatted = new Date(note.createdAt).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric'
  });

  return `
    <div class="bg-slate-800/90 border border-slate-700/80 rounded-2xl p-4 flex flex-col justify-between transition hover:border-slate-600">
      <div>
        <div class="flex items-center justify-between gap-2 mb-2">
          <span class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold" style="background-color: ${subject.color}20; color: ${subject.color}">
            <span class="w-1.5 h-1.5 rounded-full" style="background-color: ${subject.color}"></span>
            ${subject.name}
          </span>
          <div class="flex items-center gap-1">
            <span class="text-[11px] text-slate-500">${dateFormatted}</span>
            <button onclick="deleteNote('${note.id}')" class="p-1 text-slate-500 hover:text-rose-400">
              <i data-lucide="trash-2" class="w-3.5 h-3.5"></i>
            </button>
          </div>
        </div>

        <h3 class="text-sm font-bold text-white">${note.title}</h3>
        
        <div class="prose text-xs text-slate-300 mt-2 line-clamp-3">
          ${parsedMarkdown}
        </div>

        ${totalChecklist > 0 ? `
          <div class="mt-3 bg-slate-900/60 rounded-xl p-2.5 border border-slate-700/50">
            <div class="flex items-center justify-between text-[11px] font-semibold text-slate-300 mb-1.5">
              <span class="flex items-center gap-1 text-emerald-400">
                <i data-lucide="check-square" class="w-3.5 h-3.5"></i> ${doneChecklist}/${totalChecklist} topics studied
              </span>
              <span>${Math.round((doneChecklist/totalChecklist)*100)}%</span>
            </div>
            <div class="w-full bg-slate-700 h-1.5 rounded-full overflow-hidden">
              <div class="bg-emerald-500 h-full rounded-full transition-all" style="width: ${(doneChecklist/totalChecklist)*100}%"></div>
            </div>
            <div class="mt-2 space-y-1">
              ${note.checklist.map(c => `
                <div class="flex items-center gap-2 text-xs">
                  <input type="checkbox" ${c.isDone ? 'checked' : ''} onchange="toggleChecklistItem('${note.id}', '${c.id}')" class="rounded bg-slate-800 border-slate-700 text-indigo-600 focus:ring-0">
                  <span class="${c.isDone ? 'line-through text-slate-500' : 'text-slate-300'}">${c.text}</span>
                </div>
              `).join('')}
            </div>
          </div>
        ` : ''}

        ${(note.tags && note.tags.length > 0) ? `
          <div class="flex flex-wrap gap-1 mt-3">
            ${note.tags.map(t => `<span class="text-[10px] bg-slate-900 text-slate-400 px-2 py-0.5 rounded-md">#${t}</span>`).join('')}
          </div>
        ` : ''}
      </div>

      <div class="mt-4 pt-3 border-t border-slate-700/50 flex justify-end">
        <button onclick="editNote('${note.id}')" class="text-xs text-indigo-400 hover:text-indigo-300 font-semibold flex items-center gap-1">
          <i data-lucide="edit-2" class="w-3 h-3"></i> Edit Note
        </button>
      </div>
    </div>
  `;
}

function renderSchedules() {
  const container = document.getElementById('full-schedules-list');
  const filtered = state.dayFilter === 0
    ? state.schedules
    : state.schedules.filter(s => s.days.includes(state.dayFilter));

  if (filtered.length === 0) {
    container.innerHTML = `<div class="col-span-2 p-10 bg-slate-800/40 rounded-2xl text-center text-slate-500">No schedules found for this day. Click "+ Add Study Schedule" to create one!</div>`;
  } else {
    container.innerHTML = filtered.map(sch => createScheduleCardHTML(sch)).join('');
  }
  lucide.createIcons();
}

function renderNotes() {
  const container = document.getElementById('full-notes-list');
  const query = (document.getElementById('notes-search-input')?.value || '').toLowerCase();
  const subFilter = document.getElementById('notes-filter-subject')?.value || 'all';

  const filtered = state.notes.filter(n => {
    const matchesQuery = !query ||
      n.title.toLowerCase().includes(query) ||
      (n.content || '').toLowerCase().includes(query) ||
      (n.tags || []).some(t => t.toLowerCase().includes(query));

    const matchesSub = subFilter === 'all' || n.subjectId === subFilter;
    return matchesQuery && matchesSub;
  });

  if (filtered.length === 0) {
    container.innerHTML = `<div class="col-span-3 p-10 bg-slate-800/40 rounded-2xl text-center text-slate-500">No study notes match your query.</div>`;
  } else {
    container.innerHTML = filtered.map(n => createNoteCardHTML(n)).join('');
  }
  lucide.createIcons();
}

function populateSubjectDropdowns() {
  const timerSelect = document.getElementById('timer-subject-select');
  const schSelect = document.getElementById('sch-subject');
  const noteSelect = document.getElementById('note-subject');
  const noteFilter = document.getElementById('notes-filter-subject');

  const options = state.subjects.map(s => `<option value="${s.id}">${s.name}</option>`).join('');

  if (timerSelect) timerSelect.innerHTML = options;
  if (schSelect) schSelect.innerHTML = options;
  if (noteSelect) noteSelect.innerHTML = options;
  if (noteFilter) {
    noteFilter.innerHTML = `<option value="all">All Subjects</option>` + options;
  }

  // Populate note schedules dropdown
  const noteSchSelect = document.getElementById('note-schedule');
  if (noteSchSelect) {
    noteSchSelect.innerHTML = `<option value="">None (General Note)</option>` +
      state.schedules.map(s => `<option value="${s.id}">${s.title}</option>`).join('');
  }
}

// ==========================================
// Focus Timer Logic
// ==========================================
function updateTimerDisplay() {
  const mins = Math.floor(state.timer.remainingSeconds / 60);
  const secs = state.timer.remainingSeconds % 60;
  const displayStr = `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  
  const displayEl = document.getElementById('timer-display');
  if (displayEl) displayEl.innerText = displayStr;

  // SVG circle progress
  const circumference = 276.46;
  const fraction = state.timer.totalSeconds > 0
    ? (1 - state.timer.remainingSeconds / state.timer.totalSeconds)
    : 0;
  const offset = circumference * (1 - fraction);
  
  const circle = document.getElementById('timer-progress-circle');
  if (circle) circle.style.strokeDashoffset = offset;

  // Phase badge & button
  const badge = document.getElementById('timer-phase-badge');
  if (badge) {
    if (state.timer.phase === 'work') {
      badge.innerText = 'FOCUS SESSION';
      badge.className = 'text-[11px] font-bold tracking-widest uppercase text-indigo-400 bg-indigo-500/10 px-2.5 py-0.5 rounded-full border border-indigo-500/20 mb-2';
      circle.setAttribute('class', 'stroke-indigo-500 fill-none stroke-[8] transition-all duration-500 stroke-linecap-round');
    } else if (state.timer.phase === 'shortBreak') {
      badge.innerText = 'SHORT BREAK';
      badge.className = 'text-[11px] font-bold tracking-widest uppercase text-cyan-400 bg-cyan-500/10 px-2.5 py-0.5 rounded-full border border-cyan-500/20 mb-2';
      circle.setAttribute('class', 'stroke-cyan-400 fill-none stroke-[8] transition-all duration-500 stroke-linecap-round');
    } else {
      badge.innerText = 'LONG BREAK';
      badge.className = 'text-[11px] font-bold tracking-widest uppercase text-emerald-400 bg-emerald-500/10 px-2.5 py-0.5 rounded-full border border-emerald-500/20 mb-2';
      circle.setAttribute('class', 'stroke-emerald-400 fill-none stroke-[8] transition-all duration-500 stroke-linecap-round');
    }
  }

  const btnLabel = document.getElementById('timer-btn-label');
  const btnIcon = document.getElementById('timer-btn-icon');
  if (btnLabel && btnIcon) {
    if (state.timer.isRunning) {
      btnLabel.innerText = 'Pause Focus';
      btnIcon.setAttribute('data-lucide', 'pause');
    } else {
      btnLabel.innerText = state.timer.remainingSeconds < state.timer.totalSeconds ? 'Resume' : 'Start Session';
      btnIcon.setAttribute('data-lucide', 'play');
    }
    lucide.createIcons();
  }
}

function startTimer() {
  if (state.timer.isRunning) {
    // Pause
    clearInterval(state.timer.intervalId);
    state.timer.isRunning = false;
    document.getElementById('timer-status-text').innerText = 'Paused';
    updateTimerDisplay();
    return;
  }

  // Resume or start
  if (!state.timer.sessionStartTime) {
    state.timer.sessionStartTime = new Date();
    playStudyStartChime();
  }

  state.timer.isRunning = true;
  document.getElementById('timer-status-text').innerText = 'Focus in progress...';

  state.timer.intervalId = setInterval(() => {
    if (state.timer.remainingSeconds > 0) {
      state.timer.remainingSeconds--;
      updateTimerDisplay();
    } else {
      handleTimerComplete();
    }
  }, 1000);

  updateTimerDisplay();
}

function resetTimer() {
  clearInterval(state.timer.intervalId);
  state.timer.isRunning = false;
  state.timer.sessionStartTime = null;
  state.timer.remainingSeconds = state.timer.totalSeconds;
  document.getElementById('timer-status-text').innerText = 'Ready to start';
  updateTimerDisplay();
}

function handleTimerComplete() {
  clearInterval(state.timer.intervalId);
  state.timer.isRunning = false;

  const subjectId = document.getElementById('timer-subject-select').value;
  const durationMins = Math.round(state.timer.totalSeconds / 60);

  if (state.timer.phase === 'work') {
    // Log session
    state.sessions.unshift({
      id: 'sess_' + Date.now(),
      subjectId: subjectId,
      scheduleId: state.timer.activeScheduleId,
      durationMinutes: durationMins,
      date: new Date().toISOString()
    });
    persistState();
    renderDashboard();

    state.timer.completedCycles++;
    playStudyAlarmBell();
    showDesktopNotification('🎉 Focus Session Completed!', `Great work completing ${durationMins} minutes! Time for a break.`);

    if (state.timer.mode === 'pomodoro') {
      if (state.timer.completedCycles % 4 === 0) {
        state.timer.phase = 'longBreak';
        state.timer.totalSeconds = 15 * 60;
      } else {
        state.timer.phase = 'shortBreak';
        state.timer.totalSeconds = 5 * 60;
      }
    }
  } else {
    playBreakChime();
    showDesktopNotification('⚡ Break Finished!', 'Ready to begin your next focus block?');
    state.timer.phase = 'work';
    state.timer.totalSeconds = 25 * 60;
  }

  state.timer.remainingSeconds = state.timer.totalSeconds;
  state.timer.sessionStartTime = null;
  updateTimerDisplay();
}

function startSessionFromSchedule(schedule) {
  state.timer.mode = 'custom';
  state.timer.activeScheduleId = schedule.id;
  const dur = getDurationMinutes(schedule.startTime, schedule.endTime);
  state.timer.totalSeconds = dur * 60;
  state.timer.remainingSeconds = dur * 60;
  state.timer.phase = 'work';

  const select = document.getElementById('timer-subject-select');
  if (select) select.value = schedule.subjectId;

  document.getElementById('timer-mode-custom').click();
  switchTab('timer');
  startTimer();
}

function startSessionFromScheduleById(id) {
  const sch = state.schedules.find(s => s.id === id);
  if (sch) startSessionFromSchedule(sch);
}

// ==========================================
// Schedule Modal & Form Handling
// ==========================================
let editingScheduleDays = [1, 2, 3, 4, 5];

function openScheduleModal(schedule = null) {
  const modal = document.getElementById('schedule-modal');
  modal.classList.remove('hidden');

  if (schedule) {
    document.getElementById('schedule-modal-title').innerText = 'Edit Study Schedule';
    document.getElementById('sch-id').value = schedule.id;
    document.getElementById('sch-subject').value = schedule.subjectId;
    document.getElementById('sch-title').value = schedule.title;
    document.getElementById('sch-desc').value = schedule.description || '';
    document.getElementById('sch-start-time').value = schedule.startTime;
    document.getElementById('sch-end-time').value = schedule.endTime;
    document.getElementById('sch-reminder').value = schedule.reminderMins;
    editingScheduleDays = [...schedule.days];
  } else {
    document.getElementById('schedule-modal-title').innerText = 'Create Study Schedule';
    document.getElementById('schedule-form').reset();
    document.getElementById('sch-id').value = '';
    editingScheduleDays = [1, 2, 3, 4, 5];
  }
  updateScheduleDaysPicker();
}

function closeScheduleModal() {
  document.getElementById('schedule-modal').classList.add('hidden');
}

function updateScheduleDaysPicker() {
  document.querySelectorAll('.sch-day-btn').forEach(btn => {
    const day = parseInt(btn.dataset.day);
    if (editingScheduleDays.includes(day)) {
      btn.className = 'sch-day-btn flex-1 py-1.5 rounded-lg text-xs font-bold bg-indigo-600 text-white';
    } else {
      btn.className = 'sch-day-btn flex-1 py-1.5 rounded-lg text-xs font-medium bg-slate-800 text-slate-400';
    }
  });
}

function toggleScheduleActive(id) {
  const sch = state.schedules.find(s => s.id === id);
  if (sch) {
    sch.isEnabled = !sch.isEnabled;
    persistState();
    renderDashboard();
    renderSchedules();
  }
}

function editSchedule(id) {
  const sch = state.schedules.find(s => s.id === id);
  if (sch) openScheduleModal(sch);
}

// ==========================================
// Note Modal & Checklist Handling
// ==========================================
let currentChecklist = [];

function openNoteModal(note = null, defaultScheduleId = null, defaultSubjectId = null) {
  const modal = document.getElementById('note-modal');
  modal.classList.remove('hidden');

  if (note) {
    document.getElementById('note-modal-title').innerText = 'Edit Study Note';
    document.getElementById('note-id').value = note.id;
    document.getElementById('note-subject').value = note.subjectId;
    document.getElementById('note-schedule').value = note.scheduleId || '';
    document.getElementById('note-title').value = note.title;
    document.getElementById('note-content').value = note.content || '';
    document.getElementById('note-tags').value = (note.tags || []).join(', ');
    currentChecklist = [...(note.checklist || [])];
  } else {
    document.getElementById('note-modal-title').innerText = 'New Study Note';
    document.getElementById('note-form').reset();
    document.getElementById('note-id').value = '';
    if (defaultSubjectId) document.getElementById('note-subject').value = defaultSubjectId;
    if (defaultScheduleId) document.getElementById('note-schedule').value = defaultScheduleId;
    currentChecklist = [];
  }
  renderChecklistBuilder();
}

function openNoteModalForSchedule(scheduleId) {
  const sch = state.schedules.find(s => s.id === scheduleId);
  openNoteModal(null, scheduleId, sch ? sch.subjectId : null);
}

function closeNoteModal() {
  document.getElementById('note-modal').classList.add('hidden');
}

function renderChecklistBuilder() {
  const container = document.getElementById('note-checklist-items');
  container.innerHTML = currentChecklist.map((item, idx) => `
    <div class="flex items-center justify-between bg-slate-800 px-3 py-1.5 rounded-xl border border-slate-700">
      <div class="flex items-center gap-2">
        <input type="checkbox" ${item.isDone ? 'checked' : ''} onchange="currentChecklist[${idx}].isDone = this.checked" class="rounded bg-slate-900 border-slate-700 text-indigo-600">
        <span class="text-xs text-slate-200">${item.text}</span>
      </div>
      <button type="button" onclick="currentChecklist.splice(${idx}, 1); renderChecklistBuilder();" class="text-slate-500 hover:text-rose-400">
        <i data-lucide="x" class="w-3.5 h-3.5"></i>
      </button>
    </div>
  `).join('');
  lucide.createIcons();
}

function toggleChecklistItem(noteId, itemId) {
  const note = state.notes.find(n => n.id === noteId);
  if (note && note.checklist) {
    const item = note.checklist.find(c => c.id === itemId);
    if (item) {
      item.isDone = !item.isDone;
      persistState();
      renderDashboard();
      renderNotes();
    }
  }
}

function deleteNote(id) {
  if (confirm('Delete this study note?')) {
    state.notes = state.notes.filter(n => n.id !== id);
    persistState();
    renderDashboard();
    renderNotes();
  }
}

function editNote(id) {
  const note = state.notes.find(n => n.id === id);
  if (note) openNoteModal(note);
}

// ==========================================
// Analytics Charts
// ==========================================
let subjectChartInstance = null;
let weeklyChartInstance = null;

function renderAnalytics() {
  const ctxSub = document.getElementById('subjectChart')?.getContext('2d');
  const ctxWeekly = document.getElementById('weeklyChart')?.getContext('2d');
  if (!ctxSub || !ctxWeekly) return;

  // Aggregate time per subject
  const subLabels = state.subjects.map(s => s.name);
  const subColors = state.subjects.map(s => s.color);
  const subMinutes = state.subjects.map(s => {
    return state.sessions
      .filter(sess => sess.subjectId === s.id)
      .reduce((sum, sess) => sum + sess.durationMinutes, 0) / 60; // in hours
  });

  if (subjectChartInstance) subjectChartInstance.destroy();
  subjectChartInstance = new Chart(ctxSub, {
    type: 'doughnut',
    data: {
      labels: subLabels,
      datasets: [{
        data: subMinutes.every(v => v === 0) ? [1, 1, 1, 1] : subMinutes,
        backgroundColor: subColors,
        borderWidth: 2,
        borderColor: '#1e293b'
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { position: 'bottom', labels: { color: '#94a3b8', font: { size: 11 } } }
      }
    }
  });

  // Daily minutes last 7 days
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const dayLabels = [];
  const dayValues = [];
  
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dateKey = d.toISOString().slice(0, 10);
    dayLabels.push(days[d.getDay()]);
    const mins = state.sessions
      .filter(s => s.date.startsWith(dateKey))
      .reduce((sum, s) => sum + s.durationMinutes, 0);
    dayValues.push(mins);
  }

  if (weeklyChartInstance) weeklyChartInstance.destroy();
  weeklyChartInstance = new Chart(ctxWeekly, {
    type: 'bar',
    data: {
      labels: dayLabels,
      datasets: [{
        label: 'Study Minutes',
        data: dayValues,
        backgroundColor: '#6366f1',
        borderRadius: 8,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: { ticks: { color: '#94a3b8' }, grid: { color: '#334155' } },
        x: { ticks: { color: '#94a3b8' }, grid: { display: false } }
      },
      plugins: {
        legend: { display: false }
      }
    }
  });

  // Subject Goal Progress Bars
  const goalList = document.getElementById('analytics-subject-progress-list');
  if (goalList) {
    goalList.innerHTML = state.subjects.map(s => {
      const studiedMins = state.sessions
        .filter(sess => sess.subjectId === s.id)
        .reduce((sum, sess) => sum + sess.durationMinutes, 0);
      const targetMins = s.targetWeeklyHours * 60;
      const pct = Math.min(100, Math.round((studiedMins / targetMins) * 100));

      return `
        <div>
          <div class="flex items-center justify-between text-xs font-semibold mb-1">
            <span class="flex items-center gap-2 text-white">
              <span class="w-2 h-2 rounded-full" style="background-color: ${s.color}"></span>
              ${s.name}
            </span>
            <span class="text-slate-400">${studiedMins}m / ${targetMins}m (${pct}%)</span>
          </div>
          <div class="w-full bg-slate-700 h-2 rounded-full overflow-hidden">
            <div class="h-full rounded-full transition-all" style="background-color: ${s.color}; width: ${pct}%"></div>
          </div>
        </div>
      `;
    }).join('');
  }
}

// ==========================================
// Initialization & Event Listeners
// ==========================================
document.addEventListener('DOMContentLoaded', () => {
  populateSubjectDropdowns();
  renderDashboard();
  renderSchedules();
  renderNotes();
  updateTimerDisplay();
  checkNotificationPermission();

  // Notification button
  document.getElementById('enable-notif-btn')?.addEventListener('click', requestNotificationPermission);

  // Test Alarm Sound & Notification
  document.getElementById('test-alarm-btn')?.addEventListener('click', () => {
    showDesktopNotification('⏰ Test Study Notification', 'Your StudyFlow notification and chime alert are working perfectly!');
  });

  // Sound toggle button
  document.getElementById('sound-toggle-btn')?.addEventListener('click', () => {
    state.soundEnabled = !state.soundEnabled;
    persistState();
    const icon = document.getElementById('sound-icon');
    if (state.soundEnabled) {
      icon.className = 'w-4 h-4 text-emerald-400';
      playTone(659.25, 'sine', 0.2);
    } else {
      icon.className = 'w-4 h-4 text-slate-500';
    }
  });

  // Header quick note
  document.getElementById('quick-note-header-btn')?.addEventListener('click', () => openNoteModal());
  document.getElementById('timer-note-btn')?.addEventListener('click', () => {
    const activeSub = document.getElementById('timer-subject-select').value;
    openNoteModal(null, state.timer.activeScheduleId, activeSub);
  });

  // Timer mode buttons
  document.getElementById('timer-mode-pomodoro')?.addEventListener('click', () => {
    state.timer.mode = 'pomodoro';
    state.timer.totalSeconds = 25 * 60;
    state.timer.remainingSeconds = 25 * 60;
    state.timer.phase = 'work';
    document.getElementById('timer-mode-pomodoro').className = 'flex-1 py-1.5 rounded-lg text-xs font-bold bg-indigo-600 text-white transition';
    document.getElementById('timer-mode-custom').className = 'flex-1 py-1.5 rounded-lg text-xs font-medium text-slate-400 hover:text-white transition';
    document.getElementById('custom-minutes-container').classList.add('hidden');
    resetTimer();
  });

  document.getElementById('timer-mode-custom')?.addEventListener('click', () => {
    state.timer.mode = 'custom';
    state.timer.totalSeconds = 45 * 60;
    state.timer.remainingSeconds = 45 * 60;
    state.timer.phase = 'work';
    document.getElementById('timer-mode-custom').className = 'flex-1 py-1.5 rounded-lg text-xs font-bold bg-indigo-600 text-white transition';
    document.getElementById('timer-mode-pomodoro').className = 'flex-1 py-1.5 rounded-lg text-xs font-medium text-slate-400 hover:text-white transition';
    document.getElementById('custom-minutes-container').classList.remove('hidden');
    resetTimer();
  });

  // Custom minute pills
  document.querySelectorAll('.custom-min-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.custom-min-btn').forEach(b => {
        b.className = 'custom-min-btn px-3 py-1 rounded-lg text-xs font-semibold bg-slate-800 text-slate-300 border border-slate-700 hover:bg-slate-700';
      });
      btn.className = 'custom-min-btn px-3 py-1 rounded-lg text-xs font-semibold bg-indigo-600 text-white border border-indigo-500';
      const mins = parseInt(btn.dataset.min);
      state.timer.totalSeconds = mins * 60;
      state.timer.remainingSeconds = mins * 60;
      resetTimer();
    });
  });

  // Timer Start/Stop
  document.getElementById('timer-toggle-btn')?.addEventListener('click', startTimer);
  document.getElementById('timer-reset-btn')?.addEventListener('click', resetTimer);

  // Day filter pills
  document.querySelectorAll('.day-filter-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.day-filter-btn').forEach(b => {
        b.className = 'day-filter-btn px-3 py-1.5 rounded-lg text-xs font-medium bg-slate-800 text-slate-400 hover:bg-slate-700';
      });
      btn.className = 'day-filter-btn px-3 py-1.5 rounded-lg text-xs font-medium bg-indigo-600 text-white';
      state.dayFilter = parseInt(btn.dataset.day);
      renderSchedules();
    });
  });

  // Schedule days buttons inside modal
  document.querySelectorAll('.sch-day-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const day = parseInt(btn.dataset.day);
      if (editingScheduleDays.includes(day)) {
        if (editingScheduleDays.length > 1) {
          editingScheduleDays = editingScheduleDays.filter(d => d !== day);
        }
      } else {
        editingScheduleDays.push(day);
      }
      updateScheduleDaysPicker();
    });
  });

  // Schedule form submit
  document.getElementById('schedule-form')?.addEventListener('submit', (e) => {
    e.preventDefault();
    const id = document.getElementById('sch-id').value;
    const schData = {
      id: id || ('sch_' + Date.now()),
      subjectId: document.getElementById('sch-subject').value,
      title: document.getElementById('sch-title').value,
      description: document.getElementById('sch-desc').value,
      startTime: document.getElementById('sch-start-time').value,
      endTime: document.getElementById('sch-end-time').value,
      days: editingScheduleDays,
      reminderMins: parseInt(document.getElementById('sch-reminder').value),
      isEnabled: true
    };

    if (id) {
      const idx = state.schedules.findIndex(s => s.id === id);
      if (idx !== -1) state.schedules[idx] = schData;
    } else {
      state.schedules.push(schData);
    }

    persistState();
    closeScheduleModal();
    populateSubjectDropdowns();
    renderDashboard();
    renderSchedules();
  });

  // Note Checklist Add Item
  document.getElementById('note-add-check-btn')?.addEventListener('click', () => {
    const input = document.getElementById('note-check-input');
    const text = input.value.trim();
    if (text) {
      currentChecklist.push({ id: 'c_' + Date.now(), text: text, isDone: false });
      input.value = '';
      renderChecklistBuilder();
    }
  });

  // Markdown live preview toggle in note modal
  document.getElementById('note-preview-toggle-btn')?.addEventListener('click', () => {
    const textarea = document.getElementById('note-content');
    const preview = document.getElementById('note-preview-box');
    const btn = document.getElementById('note-preview-toggle-btn');
    if (preview.classList.contains('hidden')) {
      preview.innerHTML = marked.parse(textarea.value || '*No content*');
      preview.classList.remove('hidden');
      textarea.classList.add('hidden');
      btn.innerText = 'Edit Markdown';
    } else {
      preview.classList.add('hidden');
      textarea.classList.remove('hidden');
      btn.innerText = 'Preview Markdown';
    }
  });

  // Note search & filter
  document.getElementById('notes-search-input')?.addEventListener('input', renderNotes);
  document.getElementById('notes-filter-subject')?.addEventListener('change', renderNotes);

  // Note form submit
  document.getElementById('note-form')?.addEventListener('submit', (e) => {
    e.preventDefault();
    const id = document.getElementById('note-id').value;
    const tagsStr = document.getElementById('note-tags').value;
    const tags = tagsStr.split(',').map(t => t.trim()).filter(Boolean);

    const noteData = {
      id: id || ('note_' + Date.now()),
      subjectId: document.getElementById('note-subject').value,
      scheduleId: document.getElementById('note-schedule').value || null,
      title: document.getElementById('note-title').value,
      content: document.getElementById('note-content').value,
      checklist: currentChecklist,
      tags: tags,
      createdAt: id ? (state.notes.find(n => n.id === id)?.createdAt || new Date().toISOString()) : new Date().toISOString()
    };

    if (id) {
      const idx = state.notes.findIndex(n => n.id === id);
      if (idx !== -1) state.notes[idx] = noteData;
    } else {
      state.notes.unshift(noteData);
    }

    persistState();
    closeNoteModal();
    renderDashboard();
    renderNotes();
  });
});
