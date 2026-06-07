/**
 * Cleanup script: removes all seeded STUDENT, PREFECT, and LECTURER users
 * from the database, preserving the ADMIN user, all halls, all courses,
 * and all timetable entries.
 *
 * Run with: node prisma/cleanup.js
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const rolesToDelete = ['STUDENT', 'PREFECT', 'LECTURER'];

  // Find all users that will be deleted
  const usersToDelete = await prisma.user.findMany({
    where: { role: { in: rolesToDelete } },
    select: { id: true, name: true, role: true, email: true },
  });

  if (usersToDelete.length === 0) {
    console.log('No STUDENT, PREFECT, or LECTURER users found. Nothing to delete.');
    return;
  }

  const ids = usersToDelete.map((u) => u.id);
  console.log(`Found ${usersToDelete.length} users to delete:`, usersToDelete.map((u) => `${u.role}: ${u.name}`));

  // 1. Clear many-to-many student enrollments (junction table _StudentEnrollments)
  await prisma.$executeRaw`DELETE FROM "_StudentEnrollments"`;
  console.log('Cleared all student course enrollments.');

  // 2. Nullify course.lecturer_id for courses linked to these lecturers
  const lecturerIds = usersToDelete.filter((u) => u.role === 'LECTURER').map((u) => u.id);
  if (lecturerIds.length > 0) {
    await prisma.course.updateMany({
      where: { lecturer_id: { in: lecturerIds } },
      data: { lecturer_id: null },
    });
    console.log(`Cleared lecturer_id on courses for ${lecturerIds.length} lecturers.`);
  }

  // 3. Nullify course.delegate_id for delegates being deleted
  const delegateIds = usersToDelete.filter((u) => u.role === 'PREFECT').map((u) => u.id);
  if (delegateIds.length > 0) {
    await prisma.course.updateMany({
      where: { delegate_id: { in: delegateIds } },
      data: { delegate_id: null },
    });
    console.log(`Cleared delegate_id on courses for ${delegateIds.length} prefects.`);
  }

  // 4. Delete reservations made by these users
  const deletedReservations = await prisma.reservation.deleteMany({
    where: { reserved_by: { in: ids } },
  });
  console.log(`Deleted ${deletedReservations.count} reservations.`);

  // 5. Delete messages sent or received by these users
  const deletedMessages = await prisma.message.deleteMany({
    where: {
      OR: [{ sender_id: { in: ids } }, { receiver_id: { in: ids } }],
    },
  });
  console.log(`Deleted ${deletedMessages.count} messages.`);

  // 6. Delete the users
  const result = await prisma.user.deleteMany({
    where: { role: { in: rolesToDelete } },
  });
  console.log(`\nDeleted ${result.count} users.`);

  // 7. Verify remaining users
  const remaining = await prisma.user.findMany({
    select: { id: true, name: true, role: true, email: true },
  });
  console.log('\nRemaining users in database:');
  remaining.forEach((u) => console.log(`  [${u.role}] ${u.name} — ${u.email}`));

  // 8. Verify halls and courses are intact
  const hallCount = await prisma.hall.count();
  const courseCount = await prisma.course.count();
  const timetableCount = await prisma.timetableEntry.count();
  console.log(`\nPreserved: ${hallCount} halls, ${courseCount} courses, ${timetableCount} timetable entries.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
