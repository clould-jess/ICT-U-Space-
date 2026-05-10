'use client';
import { useState } from 'react';
import LiveCountdown from './LiveCountdown';

export default function StudentDashboard({ session, timetable, reservations }) {
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
  // Combine timetable and reservations into a single schedule list
  const getTodaySchedule = () => {
    const today = new Date();
    const dayOfWeek = today.toLocaleDateString('en-US', { weekday: 'long' });
    const dateString = today.toISOString().split('T')[0];

    const todaysTimetable = timetable.filter(t => t.day_of_week === dayOfWeek).map(t => ({
      id: `tt-${t.id}`,
      course: t.course.name,
      code: t.course.code,
      hall: t.hall.name,
      startTime: t.start_time,
      endTime: t.end_time,
      type: 'Official Schedule',
      color: 'var(--primary-blue)'
    }));

    const todaysReservations = reservations.filter(r => r.date === dateString && r.status === 'CONFIRMED').map(r => ({
      id: `res-${r.id}`,
      course: r.course ? r.course.name : 'Unknown Course',
      code: r.course ? r.course.code : '',
      hall: r.hall.name,
      startTime: r.start_time,
      endTime: r.end_time,
      type: 'Ad-hoc Reservation',
      color: 'var(--accent-orange)'
    }));

    const fullSchedule = [...todaysTimetable, ...todaysReservations];
    
    // Sort by start time
    return fullSchedule.sort((a, b) => a.startTime.localeCompare(b.startTime));
  };

  const schedule = getTodaySchedule();

  return (
    <div>
      <LiveCountdown timetable={timetable} reservations={reservations} />

      <div className="card" style={{ marginBottom: '2rem', background: 'linear-gradient(135deg, var(--primary-blue), #3b82f6)', color: 'white', border: 'none', boxShadow: '0 10px 25px rgba(30, 58, 138, 0.3)' }}>
        <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '0.5rem' }}>Need an empty room right now?</h3>
        <p style={{ opacity: 0.9, marginBottom: '1.5rem', fontSize: '1.05rem' }}>Click the magic button to instantly find a quiet space to study.</p>
        
        <button 
          onClick={handleMagicButton} 
          disabled={loadingMagic}
          style={{ 
            background: 'white', 
            color: 'var(--primary-blue)', 
            padding: '1rem 2rem', 
            borderRadius: '9999px', 
            fontWeight: 'bold', 
            fontSize: '1.1rem', 
            border: 'none', 
            cursor: loadingMagic ? 'default' : 'pointer',
            boxShadow: '0 4px 14px rgba(0,0,0,0.2)',
            transition: 'all 0.2s',
          }}
        >
          {loadingMagic ? 'Scanning Campus...' : '✨ Find Empty Room'}
        </button>

        {magicError && <p style={{ marginTop: '1.25rem', background: 'rgba(255,255,255,0.2)', padding: '0.75rem', borderRadius: '8px', fontWeight: '600' }}>{magicError}</p>}
        {magicHall && (
          <div style={{ marginTop: '1.5rem', background: 'rgba(255,255,255,0.15)', padding: '1rem', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.2)' }}>
            <h4 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '0.25rem' }}>🎯 Go to {magicHall.name}</h4>
            <p style={{ opacity: 0.9, fontSize: '1.05rem' }}>Located in {magicHall.building_block} • {magicHall.capacity} seats</p>
          </div>
        )}
      </div>

      <h2 style={{ fontSize: '2.25rem', fontWeight: '800', marginBottom: '1.5rem', color: 'var(--primary-blue)', letterSpacing: '-0.025em' }}>Your Schedule Today</h2>
      
      {schedule.length === 0 ? (
        <div className="card" style={{ padding: '4rem', textAlign: 'center', borderStyle: 'dashed', borderWidth: '2px' }}>
          <div style={{ fontSize: '3rem', marginBottom: '1rem', opacity: 0.5 }}>☕</div>
          <h3 style={{ fontSize: '1.25rem', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '0.5rem' }}>No classes today!</h3>
          <p style={{ color: 'var(--text-secondary)' }}>You have no classes scheduled for today. Enjoy your free time.</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          {schedule.map(item => (
            <div key={item.id} className="card" style={{ display: 'flex', padding: 0, overflow: 'hidden' }}>
              <div style={{ backgroundColor: item.color, width: '10px' }}></div>
              <div style={{ padding: '1.75rem', flex: 1, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '0.5rem' }}>
                    <h3 style={{ fontSize: '1.5rem', fontWeight: '800', color: 'var(--text-primary)', letterSpacing: '-0.01em' }}>{item.course}</h3>
                    <span style={{ 
                      fontSize: '0.75rem', 
                      fontWeight: '700', 
                      backgroundColor: item.type === 'Official Schedule' ? 'rgba(30, 58, 138, 0.1)' : 'rgba(251, 146, 60, 0.15)', 
                      color: item.color, 
                      padding: '0.35rem 0.75rem', 
                      borderRadius: '9999px',
                      textTransform: 'uppercase',
                      letterSpacing: '0.05em'
                    }}>
                      {item.type}
                    </span>
                  </div>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '1.05rem', fontWeight: '500' }}>
                    <span style={{ fontWeight: '700', color: 'var(--text-primary)' }}>{item.code}</span> &nbsp;•&nbsp; {item.hall}
                  </p>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: '1.25rem', fontWeight: '800', color: 'var(--primary-blue)' }}>{item.startTime}</div>
                  <div style={{ fontSize: '0.9rem', fontWeight: '600', color: 'var(--text-muted)' }}>until {item.endTime}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
