'use client';
import { useState, useEffect, useMemo } from 'react';
import NotificationBell from './NotificationBell';
import ProfileAvatar from './ProfileAvatar';

export default function StudentDashboard({ session, timetable, reservations, activeTab }) {
  const [magicHall, setMagicHall] = useState(null);
  const [loadingMagic, setLoadingMagic] = useState(false);
  const [magicError, setMagicError] = useState('');

  const handleMagicButton = async () => {
    setLoadingMagic(true);
    setMagicError('');
    setMagicHall(null);
    try {
      const res = await fetch('/api/halls/available-now');
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setMagicHall(data);
    } catch (err) {
      setMagicError(err.message);
    } finally {
      setLoadingMagic(false);
    }
  };

  const getTodaySchedule = useMemo(() => {
    const today = new Date();
    const dayOfWeek = today.toLocaleDateString('en-US', { weekday: 'long' });
    const dateString = today.toISOString().split('T')[0];

    const todaysTimetable = timetable.filter(t => t.day_of_week === dayOfWeek).map((t, i) => ({
      id: `tt-${t.id}`,
      course: t.course.name,
      code: t.course.code,
      hall: t.hall.name,
      startTime: t.start_time,
      endTime: t.end_time,
      lecturer: t.course.lecturer?.name || 'Staff',
      type: 'class',
      colorClass: ['border-left-blue', 'border-left-green', 'border-left-orange', 'border-left-red'][i % 4]
    }));

    const todaysReservations = reservations.filter(r => r.date === dateString && r.status === 'CONFIRMED').map((r, i) => ({
      id: `res-${r.id}`,
      course: r.course ? r.course.name : 'Unknown Course',
      code: r.course ? r.course.code : '',
      hall: r.hall.name,
      startTime: r.start_time,
      endTime: r.end_time,
      lecturer: 'Ad-hoc Reservation',
      type: 'reservation',
      colorClass: 'border-left-orange'
    }));

    const fullSchedule = [...todaysTimetable, ...todaysReservations];
    return fullSchedule.sort((a, b) => a.startTime.localeCompare(b.startTime));
  }, [timetable, reservations]);

  const schedule = getTodaySchedule;
  const [upcomingClassReminder, setUpcomingClassReminder] = useState(null);

  useEffect(() => {
    if (typeof window !== 'undefined' && 'Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }
  }, []);

  useEffect(() => {
    const checkSchedule = () => {
      const now = new Date();
      const currentHours = now.getHours();
      const currentMinutes = now.getMinutes();
      const currentTimeStr = `${currentHours.toString().padStart(2, '0')}:${currentMinutes.toString().padStart(2, '0')}`;
      
      const nextClass = schedule.find(item => item.startTime > currentTimeStr);
      
      if (nextClass) {
        const [startHours, startMinutes] = nextClass.startTime.split(':').map(Number);
        const nextClassDate = new Date();
        nextClassDate.setHours(startHours, startMinutes, 0, 0);
        
        const diffMs = nextClassDate - now;
        const diffMins = Math.floor(diffMs / 60000);
        
        if (diffMins > 0 && diffMins <= 30) {
          setUpcomingClassReminder({ class: nextClass, mins: diffMins });
        } else {
          setUpcomingClassReminder(null);
        }

        // Trigger browser notification at exactly 15 mins
        if (diffMins === 15 && typeof window !== 'undefined' && 'Notification' in window && Notification.permission === 'granted') {
          const dateString = new Date().toISOString().split('T')[0];
          const cacheKey = `notified-${nextClass.id}-${dateString}`;
          if (!localStorage.getItem(cacheKey)) {
            new Notification('Class Starting Soon!', {
              body: `${nextClass.course} starts in 15 minutes at ${nextClass.hall}.`,
            });
            localStorage.setItem(cacheKey, 'true');
          }
        }
      } else {
        setUpcomingClassReminder(null);
      }
    };

    checkSchedule();
    const interval = setInterval(checkSchedule, 60000);
    return () => clearInterval(interval);
  }, [schedule]);

  if (activeTab === 'timetable') {
    return (
      <div style={{ paddingBottom: '2rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.25rem' }}>
          <h2 style={{ fontSize: '1.75rem', fontWeight: '800', color: 'var(--text-primary)' }}>Schedule</h2>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
            <NotificationBell />
            <ProfileAvatar session={session} />
          </div>
        </div>
        <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>Your classes for today</p>
        
        {/* Horizontal Date Selector Placeholder */}
        <div style={{ display: 'flex', gap: '0.75rem', overflowX: 'auto', paddingBottom: '1rem', marginBottom: '1rem', scrollbarWidth: 'none' }}>
          {['Mon', 'Tue', 'Wed', 'Thu', 'Fri'].map((day, i) => (
            <div key={day} style={{ 
              minWidth: '60px', 
              padding: '0.75rem 0', 
              borderRadius: '16px', 
              backgroundColor: i === 0 ? 'var(--primary-blue)' : 'var(--surface-color)', 
              color: i === 0 ? 'white' : 'var(--text-primary)',
              textAlign: 'center',
              boxShadow: i === 0 ? '0 4px 12px rgba(37, 99, 235, 0.3)' : '0 2px 8px rgba(0,0,0,0.04)',
              border: i === 0 ? 'none' : '1px solid var(--border-color)'
            }}>
              <div style={{ fontSize: '0.8rem', marginBottom: '0.25rem', opacity: i === 0 ? 0.9 : 0.6 }}>{day}</div>
              <div style={{ fontSize: '1.2rem', fontWeight: '700' }}>{25 + i}</div>
            </div>
          ))}
        </div>

        <h3 style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '1rem' }}>Today</h3>

        {schedule.length === 0 ? (
          <div className="card" style={{ textAlign: 'center', padding: '3rem 1rem' }}>
            <p style={{ color: 'var(--text-secondary)' }}>No classes scheduled for today.</p>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {schedule.map(item => (
              <div key={item.id} className={`card ${item.colorClass}`} style={{ padding: '1.25rem' }}>
                <h4 style={{ fontSize: '1.1rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)' }}>{item.course}</h4>
                <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem', marginBottom: '0.25rem' }}>
                  {item.startTime} - {item.endTime} • {item.hall}
                </p>
                <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>{item.lecturer}</p>
              </div>
            ))}
          </div>
        )}
      </div>
    );
  }

  // Dashboard Tab
  return (
    <div style={{ paddingBottom: '2rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
        <div>
          <h2 style={{ fontSize: '1.75rem', fontWeight: '800', color: 'var(--text-primary)' }}>
            Welcome back, {session.name}
          </h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>Monday, April 25</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
          <NotificationBell />
          <ProfileAvatar session={session} />
        </div>
      </div>

      {upcomingClassReminder && (
        <div style={{
          backgroundColor: 'color-mix(in srgb, var(--accent-orange) 15%, transparent)',
          border: '1px solid var(--accent-orange)',
          borderRadius: '16px',
          padding: '1rem 1.5rem',
          marginBottom: '1.5rem',
          display: 'flex',
          alignItems: 'center',
          gap: '1rem',
          color: 'var(--text-primary)'
        }}>
          <div style={{ color: 'var(--accent-orange)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
          </div>
          <div>
            <h4 style={{ fontWeight: '700', fontSize: '1.05rem', marginBottom: '0.2rem' }}>Reminder: Class starting soon!</h4>
            <p style={{ fontSize: '0.9rem', color: 'var(--text-secondary)' }}>
              <strong>{upcomingClassReminder.class.course}</strong> starts in <strong>{upcomingClassReminder.mins} minutes</strong> at <strong>{upcomingClassReminder.class.hall}</strong>.
            </p>
          </div>
        </div>
      )}

      <div className="card" style={{ 
        background: 'var(--primary-blue)', 
        color: 'white', 
        marginBottom: '2rem',
        padding: '1.5rem',
        borderRadius: '24px'
      }}>
        <p style={{ fontSize: '0.9rem', opacity: 0.9, marginBottom: '0.5rem' }}>Today's overview</p>
        <h3 style={{ fontSize: '1.5rem', fontWeight: '700', lineHeight: 1.3 }}>
          {schedule.length} classes
        </h3>
      </div>

      <h3 style={{ fontSize: '1.1rem', fontWeight: '700', marginBottom: '1rem' }}>Quick actions</h3>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '1rem', marginBottom: '2rem' }}>
        <button onClick={handleMagicButton} className="card" style={{ padding: '1rem', display: 'flex', alignItems: 'center', gap: '0.75rem', textAlign: 'left', cursor: 'pointer', border: 'none' }}>
          <span style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z"/><path d="M5 3v4M3 5h4"/></svg>
          </span>
          <span style={{ fontWeight: '600', fontSize: '0.95rem' }}>Magic Find</span>
        </button>
      </div>

      {loadingMagic && <p style={{ color: 'var(--primary-blue)', marginBottom: '1rem' }}>Finding an empty room...</p>}
      {magicError && <p style={{ color: 'var(--error)', marginBottom: '1rem' }}>{magicError}</p>}
      {magicHall && (
        <div className="card border-left-blue" style={{ marginBottom: '2rem' }}>
          <h4 style={{ fontWeight: '700', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
            Go to {magicHall.name}
          </h4>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>Located in {magicHall.building_block}</p>
        </div>
      )}

      <h3 style={{ fontSize: '1.1rem', fontWeight: '700', marginBottom: '1rem' }}>Upcoming</h3>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        {schedule.slice(0, 2).map((item, i) => (
          <div key={item.id} className={`card ${item.colorClass}`} style={{ padding: '1.25rem' }}>
            <h4 style={{ fontWeight: '700', fontSize: '1.05rem', marginBottom: '0.25rem' }}>{item.course}</h4>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>Today • {item.startTime}</p>
          </div>
        ))}
        {schedule.length === 0 && (
          <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>No upcoming events.</p>
        )}
      </div>
    </div>
  );
}
