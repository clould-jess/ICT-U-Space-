'use client';
import { useState } from 'react';
import Sidebar from './Sidebar';
import AdminDashboard from './AdminDashboard';
import StudentDashboard from './StudentDashboard';
import LecturerDashboard from './LecturerDashboard';
import MessagesView from './MessagesView';

export default function DashboardLayout({ session, data }) {
  const [activeTab, setActiveTab] = useState(
    session.role === 'ADMIN' ? 'halls' : 'dashboard'
  );
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);

  return (
    <div style={{ display: 'flex', height: '100vh', overflow: 'hidden', backgroundColor: 'transparent' }}>
      <Sidebar session={session} activeTab={activeTab} setActiveTab={setActiveTab} isOpen={isSidebarOpen} />
      
      <main style={{ flex: 1, overflowY: 'auto', padding: '1.5rem 2.5rem', position: 'relative', display: 'flex', flexDirection: 'column' }}>
        <div style={{ marginBottom: '1.5rem', display: 'flex', alignItems: 'center' }}>
          <button 
            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
            style={{ 
              background: 'color-mix(in srgb, var(--surface-color) 40%, transparent)', 
              border: '1px solid color-mix(in srgb, var(--border-color) 60%, transparent)', 
              cursor: 'pointer',
              color: 'var(--text-primary)',
              padding: '0.5rem',
              marginRight: '1rem',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              borderRadius: '50%',
              transition: 'background 0.2s',
              backdropFilter: 'blur(10px)',
              WebkitBackdropFilter: 'blur(10px)'
            }}
            onMouseOver={(e) => e.currentTarget.style.background = 'color-mix(in srgb, var(--surface-color) 60%, transparent)'}
            onMouseOut={(e) => e.currentTarget.style.background = 'color-mix(in srgb, var(--surface-color) 40%, transparent)'}
            title="Toggle Menu"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <line x1="3" y1="12" x2="21" y2="12"></line>
              <line x1="3" y1="6" x2="21" y2="6"></line>
              <line x1="3" y1="18" x2="21" y2="18"></line>
            </svg>
          </button>
        </div>

        <div style={{ flex: 1 }}>
        {activeTab === 'messages' ? (
           <MessagesView session={session} />
        ) : session.role === 'ADMIN' ? (
           <AdminDashboard session={session} initialHalls={data.halls} initialCourses={data.courses} initialUsers={data.users} activeTab={activeTab} />
        ) : session.role === 'STUDENT' ? (
           <StudentDashboard session={session} timetable={data.timetable} reservations={data.reservations} activeTab={activeTab} />
        ) : (
           <LecturerDashboard session={session} initialHalls={data.halls} initialCourses={data.courses} activeTab={activeTab} />
        )}
        </div>
      </main>
    </div>
  );
}
