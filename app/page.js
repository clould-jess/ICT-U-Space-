import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { PrismaClient } from '@prisma/client';
import LecturerDashboard from './components/LecturerDashboard';
import StudentDashboard from './components/StudentDashboard';
import AdminDashboard from './components/AdminDashboard';
import NotificationBell from './components/NotificationBell';
import PushNotificationPrompt from './components/PushNotificationPrompt';
import SettingsButton from './components/SettingsButton';

const prisma = new PrismaClient();

export default async function Home() {
  const sessionCookie = (await cookies()).get('session');
  if (!sessionCookie) redirect('/login');
  
  const session = JSON.parse(sessionCookie.value);

  const halls = await prisma.hall.findMany();
  const courses = session.role === 'LECTURER' 
    ? await prisma.course.findMany({ where: { lecturer_id: session.id } }) 
    : await prisma.course.findMany({ include: { lecturer: true } });

  let timetable = [];
  let reservations = [];
  
  if (session.role === 'STUDENT') {
    const studentWithCourses = await prisma.user.findUnique({
      where: { id: session.id },
      include: { enrolledIn: { select: { id: true } } }
    });
    const courseIds = studentWithCourses?.enrolledIn.map(c => c.id) || [];

    timetable = await prisma.timetableEntry.findMany({
      where: { course_id: { in: courseIds } },
      include: { course: true, hall: true }
    });
    
    reservations = await prisma.reservation.findMany({
      where: { course_id: { in: courseIds } },
      include: { course: true, hall: true }
    });
  }

  const handleLogout = async () => {
    'use server';
    (await cookies()).delete('session');
    redirect('/login');
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <header style={{ 
        background: 'linear-gradient(90deg, var(--primary-blue) 0%, var(--primary-blue-hover) 100%)', 
        color: 'white',
        padding: '1rem 2.5rem', 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center',
        boxShadow: '0 4px 12px rgba(30, 58, 138, 0.25)'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'var(--accent-orange)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', fontSize: '1.25rem', boxShadow: '0 2px 8px rgba(251, 146, 60, 0.4)' }}>C</div>
          <h1 style={{ fontSize: '1.5rem', fontWeight: '800', letterSpacing: '-0.025em' }}>ICT-U Space</h1>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '2rem' }}>
          <div style={{ display: 'flex', gap: '1rem' }}>
            <SettingsButton session={session} />
            <NotificationBell />
          </div>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: '0.9rem', fontWeight: '600' }}>{session.name}</div>
            <div style={{ fontSize: '0.75rem', opacity: 0.8, textTransform: 'uppercase', letterSpacing: '0.05em' }}>{session.role}</div>
          </div>
          <form action={handleLogout}>
            <button type="submit" style={{ 
              background: 'rgba(255,255,255,0.1)', 
              color: 'white', 
              border: '1px solid rgba(255,255,255,0.2)', 
              padding: '0.5rem 1.25rem', 
              borderRadius: '8px', 
              cursor: 'pointer', 
              fontWeight: '600',
              transition: 'background 0.2s'
            }}>
              Sign Out
            </button>
          </form>
        </div>
      </header>

      <main style={{ flex: 1, padding: '3rem 2.5rem', maxWidth: '1400px', margin: '0 auto', width: '100%' }}>
        <PushNotificationPrompt />
        {session.role === 'STUDENT' ? (
          <StudentDashboard session={session} timetable={timetable} reservations={reservations} />
        ) : session.role === 'ADMIN' ? (
          <AdminDashboard session={session} initialHalls={halls} initialCourses={courses} />
        ) : (
          <LecturerDashboard session={session} initialHalls={halls} initialCourses={courses} />
        )}
      </main>
    </div>
  );
}
