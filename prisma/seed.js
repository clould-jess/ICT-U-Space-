const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  // Clear existing data (optional, but good for resetting)
  await prisma.reservation.deleteMany();
  await prisma.timetableEntry.deleteMany();
  await prisma.course.deleteMany();
  await prisma.hall.deleteMany();
  await prisma.user.deleteMany();

  // 1. Create Users
  const defaultPassword = 'naruto';
  const admin = await prisma.user.create({ data: { name: 'Karel Jess', email: 'admin@school.edu', password: defaultPassword, role: 'ADMIN' } });
  const lecturer1 = await prisma.user.create({ data: { name: 'Dr. Smith', email: 'smith@school.edu', password: defaultPassword, role: 'LECTURER' } });
  const lecturer2 = await prisma.user.create({ data: { name: 'Prof. Jones', email: 'jones@school.edu', password: defaultPassword, role: 'LECTURER' } });
  const prefect = await prisma.user.create({ data: { name: 'Prefect Peter', email: 'peter@student.school.edu', password: defaultPassword, role: 'PREFECT' } });
  const student = await prisma.user.create({ data: { name: 'Student Sam', email: 'sam@student.school.edu', password: defaultPassword, role: 'STUDENT' } });

  // 2. Create Halls
  const hallA = await prisma.hall.create({ data: { name: 'George Mbarika', capacity: 200, features: 'projector,AC,whiteboard', building_block: 'Main Block' } });
  const hallB = await prisma.hall.create({ data: { name: 'Pondi hall', capacity: 150, features: 'projector,whiteboard', building_block: 'Main Block' } });
  const room101 = await prisma.hall.create({ data: { name: 'French hall', capacity: 50, features: 'whiteboard', building_block: 'Science Block' } });
  const room102 = await prisma.hall.create({ data: { name: 'Chumbow hall', capacity: 60, features: 'smartboard,AC', building_block: 'Science Block' } });
  const lab1 = await prisma.hall.create({ data: { name: 'Eric Mbarika hall', capacity: 40, features: 'computers,projector,AC', building_block: 'IT Block' } });

  // 3. Create Courses
  const courseMath = await prisma.course.create({ data: { code: 'MAT101', name: 'Calculus I', enrolled_count: 120, lecturer_id: lecturer1.id, students: { connect: [{ id: student.id }] } } });
  const courseCS = await prisma.course.create({ data: { code: 'CS101', name: 'Intro to Programming', enrolled_count: 180, lecturer_id: lecturer2.id, students: { connect: [{ id: student.id }] } } });
  const coursePhysics = await prisma.course.create({ data: { code: 'PHY101', name: 'Physics I', enrolled_count: 45, lecturer_id: lecturer1.id } });

  // 4. Create Timetable Entries (Official Schedule)
  await prisma.timetableEntry.create({ data: { day_of_week: 'Monday', start_time: '09:00', end_time: '11:00', course_id: courseMath.id, hall_id: hallB.id } });
  await prisma.timetableEntry.create({ data: { day_of_week: 'Tuesday', start_time: '14:00', end_time: '16:00', course_id: courseCS.id, hall_id: hallA.id } });
  await prisma.timetableEntry.create({ data: { day_of_week: 'Wednesday', start_time: '10:00', end_time: '12:00', course_id: coursePhysics.id, hall_id: room101.id } });

  // 5. Create some Ad-Hoc Reservations
  // Let's say Dr. Smith booked Room 102 for a makeup class
  await prisma.reservation.create({
    data: {
      date: new Date().toISOString().split('T')[0], // Today
      start_time: '16:00',
      end_time: '18:00',
      status: 'CONFIRMED',
      hall_id: room102.id,
      course_id: courseMath.id,
      reserved_by: lecturer1.id
    }
  });

  console.log('Dummy data has been successfully seeded into the database!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
