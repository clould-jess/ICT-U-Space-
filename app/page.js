import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { PrismaClient } from '@prisma/client';
import DashboardLayout from './components/DashboardLayout';
import PushNotificationPrompt from './components/PushNotificationPrompt';

const prisma = new PrismaClient();

export default async function Home() {
  const sessionCookie = (await cookies()).get('session');
  if (!sessionCookie) redirect('/login');
  
  const session = JSON.parse(sessionCookie.value);

  const halls = await prisma.hall.findMany();
  const courses = await prisma.course.findMany({ include: { lecturer: true } });

  let timetable = [];
  let reservations = [];
  let users = [];
  
  if (session.role === 'ADMIN') {
    users = await prisma.user.findMany({
      select: { id: true, name: true, email: true, role: true }
    });
  }
  
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

  const data = { halls, courses, users, timetable, reservations };

  return (
    <>
      <PushNotificationPrompt />
      <DashboardLayout session={session} data={data} />
    </>
  );
}
