const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');
const prisma = new PrismaClient();

function generateBookingKey() {
  return Math.random().toString(36).substring(2, 10).toUpperCase();
}

async function main() {
  // Clear existing data
  await prisma.reservation.deleteMany();
  await prisma.timetableEntry.deleteMany();
  await prisma.notification.deleteMany();
  await prisma.message.deleteMany();
  await prisma.course.deleteMany();
  await prisma.hall.deleteMany();
  await prisma.user.deleteMany();

  // Create admin
  const defaultPassword = 'naruto';
  await prisma.user.create({ data: { name: 'Karel Jess', email: 'admin@school.edu', password: defaultPassword, role: 'ADMIN', booking_key: generateBookingKey() } });
  
  // Create prefect and student for testing
  const prefect = await prisma.user.create({ data: { name: 'Prefect Peter', email: 'peter@student.school.edu', password: defaultPassword, role: 'PREFECT', booking_key: generateBookingKey() } });
  const student = await prisma.user.create({ data: { name: 'Student Sam', email: 'sam@student.school.edu', password: defaultPassword, role: 'STUDENT', booking_key: generateBookingKey() } });

  // Read timetable data
  const dataPath = path.join(__dirname, 'timetable.json');
  const timetableData = JSON.parse(fs.readFileSync(dataPath, 'utf-8'));

  // 1. Unique Lecturers
  const lecturerNames = [...new Set(timetableData.map(entry => entry.lecturer))];
  const lecturerMap = {}; // name -> id
  for (let i = 0; i < lecturerNames.length; i++) {
    const name = lecturerNames[i];
    // Create email from name: Mr. Ekane Lesley -> ekane.lesley@school.edu
    const cleanName = name.replace(/^(Mr\.|Dr\.|Engr\.|Mgr\.|Mme|Ms\.|Prof\.)\s*/, '');
    const email = cleanName.toLowerCase().replace(/\s+/g, '.') + '@school.edu';
    
    const user = await prisma.user.create({
      data: {
        name,
        email,
        password: defaultPassword,
        role: 'LECTURER',
        booking_key: generateBookingKey()
      }
    });
    lecturerMap[name] = user.id;
  }

  // 2. Unique Halls
  const hallNames = [...new Set(timetableData.map(entry => entry.hall))];
  const hallMap = {}; // name -> id
  for (let name of hallNames) {
    let capacity = 100;
    let features = 'projector,whiteboard';
    let building_block = 'Main Block';
    
    // Add a little variety or match existing names if possible
    if (name.includes('Mbarika')) {
      capacity = 200;
      features += ',AC';
    } else if (name.includes('IT Hall') || name.includes('Lab')) {
      features += ',computers';
      building_block = 'IT Block';
    } else if (name.includes('Radio & TV Unit')) {
      capacity = 30;
      features = 'studio equipment';
      building_block = 'Media Block';
    } else if (name.includes('FRENCH HALL')) {
      capacity = 500;
      features = 'Projector';
      building_block = 'Main Block';
    }

    const hall = await prisma.hall.create({
      data: {
        name,
        capacity,
        features,
        building_block
      }
    });
    hallMap[name] = hall.id;
  }

  // 3. Unique Courses
  // Course uniqueness based on course string
  const courseNames = [...new Set(timetableData.map(entry => entry.course))];
  const courseMap = {}; // course string -> id
  
  for (let fullCourse of courseNames) {
    // Attempt to extract code like "JMC 3271" or "ICT 2230"
    const match = fullCourse.match(/^([A-Z]{3}\s*\d{4})\s*(.*)$/);
    let code = '';
    let name = '';
    if (match) {
      code = match[1];
      name = match[2];
    } else {
      // Fallback
      code = 'C-' + Math.random().toString(36).substring(7).toUpperCase();
      name = fullCourse;
    }
    
    // Some courses share the same code if they have multiple groups, e.g., ICT 1210 OOP Grp 1 and Grp 2.
    // Course code in DB must be unique. Let's make it unique if we have multiple groups
    if (fullCourse.includes('Grp')) {
      const grpMatch = fullCourse.match(/Grp\s*\d+/);
      if (grpMatch) {
         code = code + '-' + grpMatch[0].replace(' ', '');
      }
    }

    // Still check if code is unique, if not, append random chars
    let isUnique = false;
    let testCode = code;
    let attempt = 0;
    while (!isUnique) {
      const existing = await prisma.course.findUnique({ where: { code: testCode } });
      if (existing) {
        testCode = code + '-' + attempt++;
      } else {
        code = testCode;
        isUnique = true;
      }
    }

    // Find the lecturer for this course from the data (assuming one primary lecturer for the course)
    const entry = timetableData.find(e => e.course === fullCourse);
    const lecturerId = lecturerMap[entry.lecturer];

    const course = await prisma.course.create({
      data: {
        code,
        name,
        enrolled_count: 50 + Math.floor(Math.random() * 50),
        lecturer_id: lecturerId,
        delegate_id: prefect.id, // Assign prefect to all courses as delegate for testing
        students: { connect: [{ id: student.id }, { id: prefect.id }] }
      }
    });
    courseMap[fullCourse] = course.id;
  }

  // 4. Create Timetable Entries
  for (let entry of timetableData) {
    // Ensure times look like HH:mm. Parse "8:00 - 11:00"
    const times = entry.time.split('-');
    let startTime = times[0].trim();
    let endTime = times[1].trim();
    
    if (startTime.length === 4 && startTime.charAt(1) === ':') startTime = '0' + startTime;
    if (endTime.length === 4 && endTime.charAt(1) === ':') endTime = '0' + endTime;

    await prisma.timetableEntry.create({
      data: {
        day_of_week: entry.day,
        start_time: startTime,
        end_time: endTime,
        course_id: courseMap[entry.course],
        hall_id: hallMap[entry.hall]
      }
    });
  }

  console.log(`Successfully seeded ${lecturerNames.length} lecturers, ${hallNames.length} halls, ${courseNames.length} courses, and ${timetableData.length} timetable entries.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
