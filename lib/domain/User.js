/**
 * Domain Models demonstrating OOP Concepts:
 * - Encapsulation
 * - Inheritance
 * - Polymorphism
 */

class User {
  constructor(id, email, name, role) {
    this.id = id;
    this.email = email;
    this.name = name;
    this.role = role;
  }

  // Abstract method intended to be overridden (Polymorphism)
  getRolePermissions() {
    throw new Error('Method "getRolePermissions()" must be implemented.');
  }

  getProfileSummary() {
    return `[${this.role}] ${this.name} (${this.email})`;
  }
}

class Student extends User {
  constructor(id, email, name, academic_level, semester) {
    super(id, email, name, 'STUDENT');
    this.academic_level = academic_level;
    this.semester = semester;
  }

  // Polymorphism: Overriding the base method
  getRolePermissions() {
    return ['view_schedule', 'manage_enrollments'];
  }
}

class Lecturer extends User {
  constructor(id, email, name) {
    super(id, email, name, 'LECTURER');
  }

  // Polymorphism: Overriding the base method
  getRolePermissions() {
    return ['view_schedule', 'book_room', 'manage_courses'];
  }
}

class Admin extends User {
  constructor(id, email, name) {
    super(id, email, name, 'ADMIN');
  }

  // Polymorphism: Overriding the base method
  getRolePermissions() {
    return ['view_schedule', 'manage_system', 'override_bookings'];
  }
}

// Factory Method to generate the correct polymorphic object
class UserFactory {
  static create(userData) {
    switch (userData.role) {
      case 'STUDENT':
        return new Student(userData.id, userData.email, userData.name, userData.academic_level, userData.semester);
      case 'LECTURER':
        return new Lecturer(userData.id, userData.email, userData.name);
      case 'ADMIN':
        return new Admin(userData.id, userData.email, userData.name);
      default:
        return new User(userData.id, userData.email, userData.name, 'UNKNOWN');
    }
  }
}

export { User, Student, Lecturer, Admin, UserFactory };
