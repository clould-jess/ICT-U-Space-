'use client';
import { useState, useEffect, useMemo } from 'react';
import NotificationBell from './NotificationBell';
import ProfileAvatar from './ProfileAvatar';

const DAY_NAMES = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
const DAY_SHORTS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

function getWeekDays() {
  const today = new Date();
  const dow = today.getDay(); // 0=Sun
  const mondayOffset = dow === 0 ? -6 : 1 - dow;
  const monday = new Date(today);
  monday.setDate(today.getDate() + mondayOffset);
  return DAY_NAMES.map((full, i) => {
    const d = new Date(monday);
    d.setDate(monday.getDate() + i);
    const offset = d.getTimezoneOffset();
    const dateStr = new Date(d.getTime() - offset * 60000).toISOString().split('T')[0];
    return { full, short: DAY_SHORTS[i], date: d.getDate(), month: d.getMonth(), dateStr };
  });
}

function getTodayIndex() {
  const dow = new Date().getDay();
  if (dow === 0 || dow === 6) return 0;
  return dow - 1;
}

export default function StudentDashboard({ session, timetable, reservations, activeTab }) {
  const weekDays = useMemo(() => getWeekDays(), []);
  const [selectedDayIdx, setSelectedDayIdx] = useState(getTodayIndex());
  const [magicHall, setMagicHall] = useState(null);
  const [loadingMagic, setLoadingMagic] = useState(false);
  const [magicError, setMagicError] = useState('');
  const [hallStatuses, setHallStatuses] = useState([]);
  const [loadingRooms, setLoadingRooms] = useState(false);
  const [upcomingClassReminder, setUpcomingClassReminder] = useState(null);
  const [cancellingId, setCancellingId] = useState(null);
  const [cancelMsg, setCancelMsg] = useState('');

  const today = new Date();
  const dateLabel = today.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });

  const getScheduleForDay = useMemo(() => {
    return (dayIdx) => {
      const day = weekDays[dayIdx];
      if (!day) return [];

      const dayTimetable = timetable.filter(t => t.day_of_week === day.full).map((t, i) => ({
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

      const dayReservations = reservations.filter(r => r.date === day.dateStr && r.status === 'CONFIRMED').map((r, i) => ({
        id: `res-${r.id}`,
        course: r.course ? r.course.name : 'Ad-hoc',
        code: r.course ? r.course.code : '',
        hall: r.hall.name,
        startTime: r.start_time,
        endTime: r.end_time,
        lecturer: 'Reservation',
        type: 'reservation',
        colorClass: 'border-left-orange'
      }));

      return [...dayTimetable, ...dayReservations].sort((a, b) => a.startTime.localeCompare(b.startTime));
    };
  }, [timetable, reservations, weekDays]);

  const todaySchedule = useMemo(() => getScheduleForDay(getTodayIndex()), [getScheduleForDay]);
  const selectedSchedule = useMemo(() => getScheduleForDay(selectedDayIdx), [getScheduleForDay, selectedDayIdx]);

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

  const fetchRoomStatuses = async () => {
    setLoadingRooms(true);
    try {
      const res = await fetch('/api/halls/status');
      const data = await res.json();
      if (Array.isArray(data)) setHallStatuses(data);
    } catch {}
    setLoadingRooms(false);
  };

  useEffect(() => {
    if (activeTab === 'rooms') fetchRoomStatuses();
  }, [activeTab]);

  useEffect(() => {
    if (typeof window !== 'undefined' && 'Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }
  }, []);

  useEffect(() => {
    const checkSchedule = () => {
      const now = new Date();
      const currentTimeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
      const nextClass = todaySchedule.find(item => item.startTime > currentTimeStr);

      if (nextClass) {
        const [h, m] = nextClass.startTime.split(':').map(Number);
        const nextDate = new Date();
        nextDate.setHours(h, m, 0, 0);
        const diffMins = Math.floor((nextDate - now) / 60000);

        if (diffMins > 0 && diffMins <= 30) {
          setUpcomingClassReminder({ class: nextClass, mins: diffMins });
        } else {
          setUpcomingClassReminder(null);
        }

        if (diffMins === 15 && typeof window !== 'undefined' && 'Notification' in window && Notification.permission === 'granted') {
          const cacheKey = `notified-${nextClass.id}-${new Date().toISOString().split('T')[0]}`;
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
  }, [todaySchedule]);

  const handleCancelReservation = async (reservationId) => {
    setCancellingId(reservationId);
    setCancelMsg('');
    try {
      const res = await fetch('/api/reservations', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: reservationId })
      });
      if (res.ok) {
        setCancelMsg('Reservation cancelled.');
        setTimeout(() => window.location.reload(), 1200);
      }
    } catch {}
    setCancellingId(null);
  };

  const TopBar = () => (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.25rem' }}>
      <div>
        <h2 style={{ fontSize: '1.75rem', fontWeight: '800', color: 'var(--text-primary)' }}>
          {activeTab === 'dashboard' ? `Hi, ${session.name.split(' ')[0]}` :
           activeTab === 'timetable' ? 'My Schedule' :
           activeTab === 'reservations' ? 'Reservations' : 'Available Rooms'}
        </h2>
        <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>{dateLabel}</p>
      </div>
      <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
        <NotificationBell />
        <ProfileAvatar session={session} />
      </div>
    </div>
  );

  // --- TIMETABLE TAB ---
  if (activeTab === 'timetable') {
    return (
      <div style={{ paddingBottom: '2rem' }}>
        <TopBar />
        <div style={{ marginTop: '1.5rem', display: 'flex', gap: '0.6rem', overflowX: 'auto', paddingBottom: '1rem', scrollbarWidth: 'none' }}>
          {weekDays.map((day, i) => {
            const isSelected = i === selectedDayIdx;
            const isToday = i === getTodayIndex();
            return (
              <button
                key={day.full}
                onClick={() => setSelectedDayIdx(i)}
                style={{
                  minWidth: '64px',
                  padding: '0.75rem 0',
                  borderRadius: '16px',
                  backgroundColor: isSelected ? 'var(--primary-blue)' : 'var(--surface-color)',
                  color: isSelected ? 'white' : 'var(--text-primary)',
                  border: isToday && !isSelected ? '2px solid var(--primary-blue)' : isSelected ? 'none' : '1px solid var(--border-color)',
                  textAlign: 'center',
                  cursor: 'pointer',
                  transition: 'all 0.2s',
                  boxShadow: isSelected ? '0 4px 12px rgba(37,99,235,0.3)' : '0 2px 8px rgba(0,0,0,0.04)'
                }}
              >
                <div style={{ fontSize: '0.75rem', marginBottom: '0.3rem', opacity: isSelected ? 0.9 : 0.6, fontWeight: '500' }}>{day.short}</div>
                <div style={{ fontSize: '1.2rem', fontWeight: '700' }}>{day.date}</div>
                {isToday && <div style={{ width: '6px', height: '6px', borderRadius: '50%', backgroundColor: isSelected ? 'rgba(255,255,255,0.8)' : 'var(--primary-blue)', margin: '0.3rem auto 0' }} />}
              </button>
            );
          })}
        </div>

        <h3 style={{ fontSize: '1.1rem', fontWeight: '700', margin: '1rem 0' }}>
          {weekDays[selectedDayIdx]?.full} — {selectedSchedule.length} class{selectedSchedule.length !== 1 ? 'es' : ''}
        </h3>

        {selectedSchedule.length === 0 ? (
          <div className="card" style={{ textAlign: 'center', padding: '3rem 1rem' }}>
            <p style={{ color: 'var(--text-secondary)' }}>No classes on {weekDays[selectedDayIdx]?.full}.</p>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {selectedSchedule.map(item => (
              <div key={item.id} className={`card ${item.colorClass}`} style={{ padding: '1.25rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <h4 style={{ fontSize: '1.05rem', fontWeight: '700', marginBottom: '0.25rem' }}>{item.course}</h4>
                    <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem', marginBottom: '0.15rem' }}>
                      {item.startTime} - {item.endTime}
                    </p>
                    <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>{item.lecturer}</p>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <span className="badge" style={{ background: 'var(--surface-color)', color: 'var(--text-primary)', border: '1px solid var(--border-color)', display: 'block', marginBottom: '0.25rem' }}>
                      {item.hall}
                    </span>
                    {item.code && <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{item.code}</span>}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    );
  }

  // --- RESERVATIONS TAB ---
  if (activeTab === 'reservations') {
    const allReservations = [...reservations].sort((a, b) => {
      if (b.date !== a.date) return b.date.localeCompare(a.date);
      return b.start_time.localeCompare(a.start_time);
    });

    return (
      <div style={{ paddingBottom: '2rem' }}>
        <TopBar />
        <p style={{ color: 'var(--text-secondary)', margin: '0.5rem 0 1.5rem', fontSize: '0.9rem' }}>All reservations for your enrolled courses</p>

        {cancelMsg && (
          <div style={{ backgroundColor: '#d1fae5', color: '#065f46', padding: '0.75rem 1rem', borderRadius: '8px', marginBottom: '1rem', fontWeight: '600' }}>
            {cancelMsg}
          </div>
        )}

        {allReservations.length === 0 ? (
          <div className="card" style={{ textAlign: 'center', padding: '3rem' }}>
            <p style={{ color: 'var(--text-secondary)' }}>No reservations found for your courses.</p>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {allReservations.map(r => {
              const isPast = r.date < new Date().toISOString().split('T')[0];
              const isConfirmed = r.status === 'CONFIRMED';
              return (
                <div key={r.id} className="card" style={{ padding: '1.25rem', opacity: isPast ? 0.7 : 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '0.75rem' }}>
                    <div>
                      <h4 style={{ fontWeight: '700', fontSize: '1.05rem', marginBottom: '0.25rem' }}>
                        {r.course?.name || 'Ad-hoc Reservation'}
                      </h4>
                      <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
                        {r.hall.name} • {r.date} • {r.start_time} - {r.end_time}
                      </p>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flexShrink: 0 }}>
                      <span style={{
                        padding: '0.3rem 0.75rem',
                        borderRadius: '999px',
                        fontSize: '0.75rem',
                        fontWeight: '700',
                        backgroundColor: isConfirmed ? '#d1fae5' : '#fee2e2',
                        color: isConfirmed ? '#065f46' : '#b91c1c'
                      }}>
                        {r.status}
                      </span>
                      {isConfirmed && !isPast && r.reserved_by === session.id && (
                        <button
                          onClick={() => handleCancelReservation(r.id)}
                          disabled={cancellingId === r.id}
                          style={{ background: 'rgba(239,68,68,0.1)', color: '#ef4444', border: '1px solid rgba(239,68,68,0.3)', borderRadius: '6px', padding: '0.3rem 0.7rem', cursor: 'pointer', fontSize: '0.8rem', fontWeight: '600' }}
                        >
                          Cancel
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    );
  }

  // --- ROOMS TAB ---
  if (activeTab === 'rooms') {
    const freeCount = hallStatuses.filter(h => h.status === 'free').length;
    return (
      <div style={{ paddingBottom: '2rem' }}>
        <TopBar />
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', margin: '0.5rem 0 1.5rem' }}>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
            Live room availability right now
          </p>
          <button onClick={fetchRoomStatuses} style={{ background: 'var(--surface-color)', border: '1px solid var(--border-color)', borderRadius: '8px', padding: '0.5rem 1rem', cursor: 'pointer', fontSize: '0.85rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2"/></svg>
            Refresh
          </button>
        </div>

        {hallStatuses.length > 0 && (
          <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem' }}>
            <div className="card" style={{ flex: 1, padding: '1rem', textAlign: 'center' }}>
              <div style={{ fontSize: '2rem', fontWeight: '800', color: 'var(--success)' }}>{freeCount}</div>
              <div style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>Available</div>
            </div>
            <div className="card" style={{ flex: 1, padding: '1rem', textAlign: 'center' }}>
              <div style={{ fontSize: '2rem', fontWeight: '800', color: 'var(--error)' }}>{hallStatuses.length - freeCount}</div>
              <div style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>Occupied</div>
            </div>
            <div className="card" style={{ flex: 1, padding: '1rem', textAlign: 'center' }}>
              <div style={{ fontSize: '2rem', fontWeight: '800', color: 'var(--primary-blue)' }}>{hallStatuses.length}</div>
              <div style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>Total</div>
            </div>
          </div>
        )}

        {loadingRooms ? (
          <div className="card" style={{ textAlign: 'center', padding: '3rem' }}>
            <p style={{ color: 'var(--text-muted)' }}>Checking room availability...</p>
          </div>
        ) : hallStatuses.length === 0 ? (
          <div className="card" style={{ textAlign: 'center', padding: '3rem' }}>
            <p style={{ color: 'var(--text-muted)' }}>No rooms found. Try refreshing.</p>
          </div>
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1rem' }}>
            {hallStatuses.map(hall => (
              <div key={hall.id} className="card" style={{ padding: '1.25rem', borderLeft: `4px solid ${hall.status === 'free' ? 'var(--success)' : 'var(--error)'}`, borderTopLeftRadius: '8px', borderBottomLeftRadius: '8px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.75rem' }}>
                  <h4 style={{ fontWeight: '700', fontSize: '1.05rem' }}>{hall.name}</h4>
                  <span style={{
                    padding: '0.25rem 0.65rem', borderRadius: '999px', fontSize: '0.75rem', fontWeight: '700',
                    backgroundColor: hall.status === 'free' ? '#d1fae5' : '#fee2e2',
                    color: hall.status === 'free' ? '#065f46' : '#b91c1c'
                  }}>
                    {hall.status === 'free' ? 'Free' : 'Occupied'}
                  </span>
                </div>
                <p style={{ color: 'var(--text-secondary)', fontSize: '0.82rem', marginBottom: '0.5rem' }}>
                  {hall.building_block} • {hall.capacity} seats
                </p>
                <p style={{ color: 'var(--text-muted)', fontSize: '0.78rem' }}>
                  {hall.features?.split(',').join(' • ')}
                </p>
                {hall.status === 'busy' && hall.currentActivity && (
                  <div style={{ marginTop: '0.75rem', padding: '0.5rem 0.75rem', borderRadius: '6px', backgroundColor: 'rgba(239,68,68,0.06)', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                    In use: {hall.currentActivity.course?.name || 'Reservation'} until {hall.currentActivity.end_time}
                  </div>
                )}
                {hall.status === 'free' && hall.nextClass && (
                  <div style={{ marginTop: '0.75rem', padding: '0.5rem 0.75rem', borderRadius: '6px', backgroundColor: 'rgba(16,185,129,0.06)', fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                    Next: {hall.nextClass.course?.name} at {hall.nextClass.start_time}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    );
  }

  // --- DASHBOARD TAB (default) ---
  return (
    <div style={{ paddingBottom: '2rem' }}>
      <TopBar />

      {upcomingClassReminder && (
        <div style={{ backgroundColor: 'color-mix(in srgb, var(--accent-orange) 15%, transparent)', border: '1px solid var(--accent-orange)', borderRadius: '16px', padding: '1rem 1.5rem', marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="var(--accent-orange)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
          <div>
            <h4 style={{ fontWeight: '700', fontSize: '1rem', marginBottom: '0.15rem' }}>Class starting soon!</h4>
            <p style={{ fontSize: '0.9rem', color: 'var(--text-secondary)' }}>
              <strong>{upcomingClassReminder.class.course}</strong> in <strong>{upcomingClassReminder.mins} min</strong> at <strong>{upcomingClassReminder.class.hall}</strong>
            </p>
          </div>
        </div>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '1rem', marginBottom: '1.5rem' }}>
        <div className="card" style={{ background: 'var(--primary-blue)', color: 'white', padding: '1.5rem' }}>
          <p style={{ fontSize: '0.85rem', opacity: 0.85, marginBottom: '0.35rem' }}>Today's classes</p>
          <h3 style={{ fontSize: '2rem', fontWeight: '800' }}>{todaySchedule.length}</h3>
        </div>
        <div className="card" style={{ background: 'var(--accent-orange)', color: 'white', padding: '1.5rem' }}>
          <p style={{ fontSize: '0.85rem', opacity: 0.85, marginBottom: '0.35rem' }}>Reservations</p>
          <h3 style={{ fontSize: '2rem', fontWeight: '800' }}>{reservations.filter(r => r.status === 'CONFIRMED').length}</h3>
        </div>
      </div>

      <h3 style={{ fontSize: '1.05rem', fontWeight: '700', marginBottom: '0.75rem' }}>Quick actions</h3>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem', marginBottom: '2rem' }}>
        <button onClick={handleMagicButton} disabled={loadingMagic} className="card" style={{ padding: '1rem', display: 'flex', alignItems: 'center', gap: '0.6rem', cursor: 'pointer', border: 'none', textAlign: 'left' }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--accent-orange)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z"/><path d="M5 3v4M3 5h4"/></svg>
          <div>
            <div style={{ fontWeight: '700', fontSize: '0.9rem' }}>Magic Find</div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Find empty room</div>
          </div>
        </button>
        <div className="card" style={{ padding: '1rem', display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--primary-blue)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          <div>
            <div style={{ fontWeight: '700', fontSize: '0.9rem' }}>Enrolled</div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Open Settings</div>
          </div>
        </div>
      </div>

      {loadingMagic && <p style={{ color: 'var(--primary-blue)', marginBottom: '1rem', fontSize: '0.9rem' }}>Finding an empty room...</p>}
      {magicError && <p style={{ color: 'var(--error)', marginBottom: '1rem', fontSize: '0.9rem' }}>{magicError}</p>}
      {magicHall && (
        <div className="card border-left-blue" style={{ marginBottom: '1.5rem', padding: '1rem 1.25rem' }}>
          <h4 style={{ fontWeight: '700', marginBottom: '0.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
            Go to {magicHall.name}
          </h4>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>{magicHall.building_block} • {magicHall.capacity} seats</p>
        </div>
      )}

      <h3 style={{ fontSize: '1.05rem', fontWeight: '700', marginBottom: '0.75rem' }}>Today's classes</h3>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
        {todaySchedule.length === 0 ? (
          <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>No classes today. Enjoy your day!</p>
        ) : (
          todaySchedule.map(item => (
            <div key={item.id} className={`card ${item.colorClass}`} style={{ padding: '1rem 1.25rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <h4 style={{ fontWeight: '700', fontSize: '1rem', marginBottom: '0.2rem' }}>{item.course}</h4>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '0.82rem' }}>{item.startTime} – {item.endTime} • {item.hall}</p>
                </div>
                <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', textAlign: 'right' }}>{item.lecturer}</span>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
