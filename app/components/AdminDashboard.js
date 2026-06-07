'use client';

import { useState } from 'react';

export default function AdminDashboard({ session, initialHalls, initialCourses, initialUsers, activeTab }) {
  const [halls, setHalls] = useState(initialHalls);
  const [courses, setCourses] = useState(initialCourses);
  const [users, setUsers] = useState(initialUsers || []);
  
  // New Hall state
  const [hallName, setHallName] = useState('');
  const [hallCapacity, setHallCapacity] = useState('');
  const [hallFeatures, setHallFeatures] = useState('');
  const [hallBlock, setHallBlock] = useState('');
  
  // New Course state
  const [courseCode, setCourseCode] = useState('');
  const [courseName, setCourseName] = useState('');
  const [courseEnrolled, setCourseEnrolled] = useState('');
  const [courseLecturerId, setCourseLecturerId] = useState('');
  const [courseDelegateId, setCourseDelegateId] = useState('');
  
  // New Event state
  const [eventName, setEventName] = useState('');
  const [eventDate, setEventDate] = useState('');
  const [eventStart, setEventStart] = useState('');
  const [eventEnd, setEventEnd] = useState('');
  const [eventHallId, setEventHallId] = useState('');
  const [reservations, setReservations] = useState([]);
  const [reservationsFetched, setReservationsFetched] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const [editingHallId, setEditingHallId] = useState(null);
  const [editCapacity, setEditCapacity] = useState('');
  
  const [updatingUserId, setUpdatingUserId] = useState(null);

  // Fetch reservations on tab switch
  if (activeTab === 'reservations' && !reservationsFetched && !loading) {
    setLoading(true);
    fetch('/api/reservations')
      .then(res => res.json())
      .then(data => { setReservations(data); setReservationsFetched(true); })
      .finally(() => setLoading(false));
  }

  const handleUpdateRole = async (userId, newRole) => {
    setUpdatingUserId(userId); setError(''); setSuccess('');
    try {
      const res = await fetch(`/api/admin/users/${userId}/role`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ role: newRole })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      
      setUsers(users.map(u => u.id === userId ? { ...u, role: newRole } : u));
      setSuccess('User role updated successfully!');
    } catch (err) {
      setError(err.message || 'Failed to update role');
    } finally {
      setUpdatingUserId(null);
    }
  };

  const handleUpdateCapacity = async (hallId) => {
    setLoading(true); setError(''); setSuccess('');
    try {
      const res = await fetch('/api/admin/halls', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: hallId,
          capacity: parseInt(editCapacity)
        })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      
      setHalls(halls.map(h => h.id === hallId ? { ...h, capacity: data.capacity } : h));
      setSuccess('Capacity updated successfully!');
      setEditingHallId(null);
    } catch (err) {
      setError(err.message || 'Failed to update capacity');
    } finally {
      setLoading(false);
    }
  };

  const handleAddHall = async (e) => {
    e.preventDefault();
    setLoading(true); setError(''); setSuccess('');
    try {
      const res = await fetch('/api/admin/halls', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: hallName,
          capacity: parseInt(hallCapacity),
          features: hallFeatures,
          building_block: hallBlock
        })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setHalls([...halls, data]);
      setSuccess('Hall added successfully!');
      setHallName(''); setHallCapacity(''); setHallFeatures(''); setHallBlock('');
    } catch (err) {
      setError(err.message || 'Failed to add hall');
    } finally {
      setLoading(false);
    }
  };

  const handleAddCourse = async (e) => {
    e.preventDefault();
    if (!courseLecturerId) {
      setError('Please select a lecturer for the course');
      return;
    }
    setLoading(true); setError(''); setSuccess('');
    try {
      const res = await fetch('/api/admin/courses', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          code: courseCode,
          name: courseName,
          enrolled_count: parseInt(courseEnrolled),
          lecturer_id: courseLecturerId,
          delegate_id: courseDelegateId || undefined
        })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setCourses([...courses, data]);
      setSuccess('Course added successfully!');
      setCourseCode(''); setCourseName(''); setCourseEnrolled(''); setCourseLecturerId('');
    } catch (err) {
      setError(err.message || 'Failed to add course');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteCourse = async (courseId) => {
    if (!confirm('Are you sure you want to delete this course? This will also delete any related timetable entries and reservations.')) return;
    setLoading(true); setError(''); setSuccess('');
    try {
      const res = await fetch(`/api/admin/courses?id=${courseId}`, {
        method: 'DELETE',
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setCourses(courses.filter(c => c.id !== courseId));
      setSuccess('Course deleted successfully!');
    } catch (err) {
      setError(err.message || 'Failed to delete course');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteReservation = async (resId) => {
    if (!confirm('Are you sure you want to unbook this reservation?')) return;
    setLoading(true); setError(''); setSuccess('');
    try {
      const res = await fetch(`/api/reservations/${resId}`, { method: 'DELETE' });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setReservations(reservations.filter(r => r.id !== resId));
      setSuccess('Reservation unbooked successfully!');
    } catch (err) {
      setError(err.message || 'Failed to unbook reservation');
    } finally {
      setLoading(false);
    }
  };

  const handleAddEvent = async (e) => {
    e.preventDefault();
    setLoading(true); setError(''); setSuccess('');
    try {
      const res = await fetch('/api/reservations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          date: eventDate,
          start_time: eventStart,
          end_time: eventEnd,
          hall_id: eventHallId,
          event_name: eventName,
          force_booking: true // Admins force book events
        })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      
      setSuccess('Event booked successfully!');
      setReservationsFetched(false); // force refetch
      setEventName(''); setEventDate(''); setEventStart(''); setEventEnd(''); setEventHallId('');
    } catch (err) {
      setError(err.message || 'Failed to book event');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateCoursePersonnel = async (courseId, lecturerId, delegateId) => {
    setLoading(true); setError(''); setSuccess('');
    try {
      const res = await fetch(`/api/courses/${courseId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ lecturer_id: lecturerId, delegate_id: delegateId })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setCourses(courses.map(c => c.id === courseId ? { ...c, lecturer_id: data.course.lecturer_id, delegate_id: data.course.delegate_id, lecturer: users.find(u => u.id === data.course.lecturer_id) || c.lecturer } : c));
      setSuccess('Course personnel updated successfully!');
    } catch (err) {
      setError(err.message || 'Failed to update course personnel');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <h2 style={{ fontSize: '2.25rem', fontWeight: '800', color: 'var(--primary-blue)', letterSpacing: '-0.025em' }}>Admin Dashboard</h2>
      </div>

      {error && <div style={{ backgroundColor: '#fee2e2', color: '#b91c1c', padding: '1rem', borderRadius: '8px', marginBottom: '1.5rem', fontWeight: '600' }}>{error}</div>}
      {success && <div style={{ backgroundColor: '#d1fae5', color: '#065f46', padding: '1rem', borderRadius: '8px', marginBottom: '1.5rem', fontWeight: '600' }}>✓ {success}</div>}

      {activeTab === 'halls' ? (
        <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
          {/* Add Hall Form */}
          <div className="card" style={{ flex: 1, minWidth: '300px' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '1.5rem', color: 'var(--primary-blue)', letterSpacing: '-0.01em' }}>Add New Space</h3>
            <form onSubmit={handleAddHall} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Space Name</label>
                <input type="text" required value={hallName} onChange={e => setHallName(e.target.value)} className="input-field" placeholder="e.g. Auditorium C" />
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Capacity</label>
                <input type="number" required value={hallCapacity} onChange={e => setHallCapacity(e.target.value)} className="input-field" placeholder="e.g. 200" />
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Features (comma separated)</label>
                <input type="text" required value={hallFeatures} onChange={e => setHallFeatures(e.target.value)} className="input-field" placeholder="projector, whiteboard, AC" />
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Building Block</label>
                <input type="text" required value={hallBlock} onChange={e => setHallBlock(e.target.value)} className="input-field" placeholder="Main Block" />
              </div>
              <button type="submit" disabled={loading} className="btn-primary" style={{ marginTop: '0.5rem', padding: '1rem', fontSize: '1.05rem' }}>
                {loading ? 'Adding...' : 'Save Space'}
              </button>
            </form>
          </div>

          {/* List of Halls */}
          <div style={{ flex: 2, minWidth: '350px', display: 'grid', gap: '1rem' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '0.5rem', color: 'var(--primary-blue)' }}>Existing Spaces</h3>
            {halls.map(hall => (
              <div key={hall.id} className="card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1.25rem' }}>
                <div>
                  <h4 style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '0.25rem' }}>{hall.name}</h4>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>{hall.building_block} • {hall.features.split(',').join(', ')}</p>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  {editingHallId === hall.id ? (
                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                      <input 
                        type="number" 
                        value={editCapacity} 
                        onChange={(e) => setEditCapacity(e.target.value)} 
                        style={{ width: '80px', padding: '0.4rem', borderRadius: '4px', border: '1px solid var(--border-color)', background: 'var(--surface-color)', color: 'var(--text-primary)' }}
                        autoFocus
                      />
                      <button onClick={() => handleUpdateCapacity(hall.id)} style={{ background: 'var(--primary-blue)', color: 'white', border: 'none', padding: '0.4rem 0.8rem', borderRadius: '4px', cursor: 'pointer' }}>Save</button>
                      <button onClick={() => setEditingHallId(null)} style={{ background: 'transparent', color: 'var(--text-muted)', border: 'none', cursor: 'pointer' }}>Cancel</button>
                    </div>
                  ) : (
                    <>
                      <span className="badge badge-orange" style={{ padding: '0.4rem 0.8rem', fontSize: '0.85rem' }}>{hall.capacity} seats</span>
                      <button 
                        onClick={() => { setEditingHallId(hall.id); setEditCapacity(hall.capacity); }} 
                        style={{ background: 'transparent', border: '1px solid var(--border-color)', borderRadius: '4px', padding: '0.3rem 0.6rem', cursor: 'pointer', color: 'var(--text-secondary)' }}
                        title="Edit Capacity"
                      >
                        ✏️
                      </button>
                    </>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : activeTab === 'courses' ? (
        <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
          {/* Add Course Form */}
          <div className="card" style={{ flex: 1, minWidth: '300px' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '1.5rem', color: 'var(--primary-blue)', letterSpacing: '-0.01em' }}>Add New Course</h3>
            <form onSubmit={handleAddCourse} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Course Code</label>
                <input type="text" required value={courseCode} onChange={e => setCourseCode(e.target.value)} className="input-field" placeholder="e.g. CS202" />
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Course Name</label>
                <input type="text" required value={courseName} onChange={e => setCourseName(e.target.value)} className="input-field" placeholder="e.g. Data Structures" />
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Enrolled Students</label>
                <input type="number" required value={courseEnrolled} onChange={e => setCourseEnrolled(e.target.value)} className="input-field" placeholder="e.g. 150" />
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Lecturer</label>
                <select required value={courseLecturerId} onChange={e => setCourseLecturerId(e.target.value)} className="input-field">
                  <option value="">Select a Lecturer</option>
                  {users.filter(u => u.role === 'LECTURER' || u.role === 'ADMIN').map(user => (
                    <option key={user.id} value={user.id}>{user.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Class Delegate (Optional)</label>
                <select value={courseDelegateId} onChange={e => setCourseDelegateId(e.target.value)} className="input-field">
                  <option value="">Select a Delegate</option>
                  {users.filter(u => u.role === 'STUDENT' || u.role === 'PREFECT').map(user => (
                    <option key={user.id} value={user.id}>{user.name}</option>
                  ))}
                </select>
              </div>
              <button type="submit" disabled={loading} className="btn-primary" style={{ marginTop: '0.5rem', padding: '1rem', fontSize: '1.05rem' }}>
                {loading ? 'Adding...' : 'Save Course'}
              </button>
            </form>
          </div>

          {/* List of Courses */}
          <div style={{ flex: 2, minWidth: '350px', display: 'grid', gap: '1rem' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '0.5rem', color: 'var(--primary-blue)' }}>Existing Courses</h3>
            {courses.map(course => (
              <div key={course.id} className="card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1.25rem' }}>
                <div>
                  <h4 style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '0.25rem' }}>{course.code} - {course.name}</h4>
                  <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center', flexWrap: 'wrap', marginTop: '0.5rem' }}>
                    <select 
                      value={course.lecturer_id || ''} 
                      onChange={e => handleUpdateCoursePersonnel(course.id, e.target.value, course.delegate_id)}
                      className="input-field" style={{ padding: '0.3rem', width: 'auto', fontSize: '0.85rem' }}
                    >
                      <option value="">Select Lecturer</option>
                      {users.filter(u => u.role === 'LECTURER' || u.role === 'ADMIN').map(user => <option key={user.id} value={user.id}>{user.name}</option>)}
                    </select>
                    <select 
                      value={course.delegate_id || ''} 
                      onChange={e => handleUpdateCoursePersonnel(course.id, course.lecturer_id, e.target.value)}
                      className="input-field" style={{ padding: '0.3rem', width: 'auto', fontSize: '0.85rem' }}
                    >
                      <option value="">Select Delegate</option>
                      {users.filter(u => u.role === 'STUDENT' || u.role === 'PREFECT').map(user => <option key={user.id} value={user.id}>{user.name}</option>)}
                    </select>
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <span className="badge" style={{ backgroundColor: 'var(--text-primary)', padding: '0.4rem 0.8rem', fontSize: '0.85rem' }}>{course.enrolled_count} students</span>
                  <button 
                    onClick={() => handleDeleteCourse(course.id)}
                    style={{ background: 'rgba(239, 68, 68, 0.1)', color: 'var(--error)', border: '1px solid rgba(239, 68, 68, 0.3)', borderRadius: '4px', padding: '0.4rem', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
                    title="Delete Course"
                    disabled={loading}
                  >
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"></path><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : activeTab === 'reservations' ? (
        <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
          {/* Add Event Form */}
          <div className="card" style={{ flex: 1, minWidth: '300px' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '1.5rem', color: 'var(--primary-blue)', letterSpacing: '-0.01em' }}>Force Book Event</h3>
            <form onSubmit={handleAddEvent} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Event Name</label>
                <input type="text" required value={eventName} onChange={e => setEventName(e.target.value)} className="input-field" placeholder="e.g. Matriculation Ceremony" />
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Date</label>
                <input type="date" required value={eventDate} onChange={e => setEventDate(e.target.value)} className="input-field" />
              </div>
              <div style={{ display: 'flex', gap: '1rem' }}>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Start</label>
                  <input type="time" required value={eventStart} onChange={e => setEventStart(e.target.value)} className="input-field" />
                </div>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>End</label>
                  <input type="time" required value={eventEnd} onChange={e => setEventEnd(e.target.value)} className="input-field" />
                </div>
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Space</label>
                <select required value={eventHallId} onChange={e => setEventHallId(e.target.value)} className="input-field">
                  <option value="">Select a Space</option>
                  {halls.map(h => <option key={h.id} value={h.id}>{h.name}</option>)}
                </select>
              </div>
              <button type="submit" disabled={loading} className="btn-primary" style={{ marginTop: '0.5rem', padding: '1rem', fontSize: '1.05rem', backgroundColor: '#ef4444' }}>
                {loading ? 'Processing...' : 'Force Book Now'}
              </button>
            </form>
          </div>

          {/* List of Reservations */}
          <div style={{ flex: 2, minWidth: '350px', display: 'grid', gap: '1rem' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '0.5rem', color: 'var(--primary-blue)' }}>All Reservations</h3>
            {reservations.length === 0 && <p>No reservations found.</p>}
            {reservations.map(res => (
              <div key={res.id} className="card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1.25rem', borderLeft: res.type === 'EVENT' ? '4px solid #ef4444' : '4px solid var(--primary-blue)' }}>
                <div>
                  <h4 style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '0.25rem' }}>
                    {res.type === 'EVENT' ? res.event_name : (res.course?.code + ' - ' + res.course?.name)}
                  </h4>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
                    {res.date} • {res.start_time} - {res.end_time} • {res.hall?.name}
                  </p>
                  <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>Booked by: {res.user?.name}</p>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <button 
                    onClick={() => handleDeleteReservation(res.id)}
                    style={{ background: 'rgba(239, 68, 68, 0.1)', color: 'var(--error)', border: '1px solid rgba(239, 68, 68, 0.3)', borderRadius: '4px', padding: '0.4rem 0.8rem', cursor: 'pointer', fontWeight: '600' }}
                    title="Unbook Reservation"
                    disabled={loading}
                  >
                    Unbook
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div style={{ display: 'grid', gap: '1rem' }}>
          <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '0.5rem', color: 'var(--primary-blue)' }}>User Management</h3>
          <div className="card" style={{ padding: '1.25rem', overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-color)' }}>
                  <th style={{ padding: '1rem', color: 'var(--text-secondary)' }}>Name</th>
                  <th style={{ padding: '1rem', color: 'var(--text-secondary)' }}>Email</th>
                  <th style={{ padding: '1rem', color: 'var(--text-secondary)' }}>Current Role</th>
                  <th style={{ padding: '1rem', color: 'var(--text-secondary)' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map(user => (
                  <tr key={user.id} style={{ borderBottom: '1px solid var(--border-color)' }}>
                    <td style={{ padding: '1rem', fontWeight: '500' }}>{user.name}</td>
                    <td style={{ padding: '1rem' }}>{user.email}</td>
                    <td style={{ padding: '1rem' }}>
                      <span className="badge" style={{ backgroundColor: 'var(--surface-color)', border: '1px solid var(--border-color)', color: 'var(--text-primary)' }}>{user.role}</span>
                    </td>
                    <td style={{ padding: '1rem' }}>
                      {user.id !== session.id ? (
                        <select 
                          disabled={updatingUserId === user.id}
                          value={user.role}
                          onChange={(e) => handleUpdateRole(user.id, e.target.value)}
                          className="input-field"
                          style={{ padding: '0.4rem 0.8rem', width: 'auto', background: 'var(--surface-color)' }}
                        >
                          <option value="STUDENT">Student</option>
                          <option value="PREFECT">Prefect</option>
                          <option value="LECTURER">Lecturer</option>
                          <option value="ADMIN">Admin</option>
                        </select>
                      ) : (
                        <span style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>It's you</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
