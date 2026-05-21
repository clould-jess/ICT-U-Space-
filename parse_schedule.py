import json
import re

raw_data = """
SPRING 2026 COMBINED UNDERGRADUATE LECTURE TIMETABLE
English Speaking Sub-Section
MONDAY
TIME COURSE LECTURER HALL
8:00 – 11:00
JMC 3271 Digital Marketing Mr. Ekane Lesley Terry & Linda Byrd Hall
ICT 2230 Intro to IOT & Embedded Systems Grp 2 Dr. Keyampi BS Chumbow Hall
ICT 1210 OOP with C++ Grp 1 Dr. Nkandeu J-E. Pondi Hall
CSC 3221 Intro to Data Science Grp 2 Dr. Fotsing Eric Mbarika Hall
BMS 3235 Project Management Dr. Agbor Nchacha IT Hall
ICT 2235 Database Management Systems Grp 1 Engr. Tanwi George Mbarika Hall
11:00 – 14:00
CSC 1121 Research Methodology for CS Engineers Grp 1 Dr. Fotsing George Mbarika Hall
ISN 3232 CCNA 2 Engr. Andrew IT Hall
ICT 2223 Java Programming II Grp 2 Engr. Mughe J-E. Pondi Hall
ACC 3210 Fundamental Principles of Taxation (ECOWAS/CEMAC) Mgr. Ayuk Collins Terry & Linda Byrd Hall
ICT 2230 Intro to IOT & Embedded Systems Grp 1 Dr. Keyampi BS Chumbow Hall
REN 3262 Application of Renewable Energy Software Engr. Djongagew Eric Mbarika Hall
14:00 – 17:00
ACC 1212 Accounting Information Systems Mr. Njabe Charles IT Hall
ICT 2223 Java Programming II Grp 1 Engr. Mughe George Mbarika Hall
SEN 3243 Advanced Web Development Grp 2 Engr. Tanwi BS Chumbow Hall
REN 3264 Power Plant Technology Engr. Djongagew Terry & Linda Byrd Hall
BMS 2200 Civics and Ethics (Grp 2 + BMS Students) Dr. Ndah J-E. Pondi Hall
TUESDAY
TIME COURSE LECTURER HALL
8:00 – 11:00
REN 3265 Embedded Systems Dr. Nkandeu IT Hall
MTH 1201 Real Analysis II Grp 1 Engr. Nebasi J-E. Pondi Hall
ACC 3217 Financial Accounting Mme Atemlefeh Vanessa Terry & Linda Byrd Hall
MTH 2222 Computational Mathematics Grp 2 Engr. Andrew George Mbarika Hall
SEN 3242 Android App Development Grp 1 Engr. Moune BS Chumbow Hall
JMC 2272 Newspaper Editing and Printing Mme Agnang Eric Mbarika Hall
TUESDAY
TIME COURSE LECTURER HALL
11:00 – 14:00
ACC 4214 Forensic Accounting Mme Atemlefeh Vanessa IT Hall
MTH 2222 Computational Mathematics Grp 1 Engr. Andrew J-E. Pondi Hall
BNF 4227 Public Finance Mr. Aben Jacob Terry & Linda Byrd Hall
SEN 3242 Android App Development Grp 2 Engr. Moune BS Chumbow Hall
JMC 3275 Film & Documentary Making Mme Agnang Eric Mbarika Hall
ICT 1210 OOP with C++ Grp 2 Dr. Nkandeu J-E. Pondi Hall
14:00 – 17:00
ACC 4211 Government Accounting Mgr. Ayuk Collins Eric Mbarika Hall
ICT 1222 Algorithms & Data Structures II Grp 1 Engr. Andrew J-E. Pondi Hall
BNF 3225 International Finance Mr. Aben Jacob IT Hall
BMS 2237 Seminar in Sustainable Development II Mr. Epie Ananfah Terry & Linda Byrd Hall
MTH 1201 Real Analysis II Grp 2 Engr. Nebasi George Mbarika Hall
WEDNESDAY
TIME COURSE LECTURER HALL
8:00 – 11:00
JMC 2276 Music Production Mme Tita Terry & Linda Byrd Hall
ECN 1242 Principles of Macroeconomics Mr. Ekane Lesley IT Hall
ICT 2235 Database Management Systems Grp 2 Engr. Tanwi George Mbarika Hall
SEN 3244 Software Architecture Engr. Palma BS Chumbow Hall
BMS 2200 Civics and Ethics Grp 1 Dr. Ndah Grimbald J-E. Pondi Hall
BMS 4238 Project Management Dr. Fosso Eric Mbarika Hall
11:00 – 14:00
ICT 1220 Intro to Networking Grp 2 Engr. Andrew George Mbarika Hall
SEN 3241 Software Validation and Verification Engr. Palma BS Chumbow Hall
BMS 1232 Knowledge Leadership & African Dev. (Grp 1 + BMS) Dr. Ndah Grimbald J-E. Pondi Hall
SEN 2243 Intro to Game Development Engr. Moune IT Hall
BNF 4228 Investment Analysis Mr. Ekane Lesley Terry & Linda Byrd Hall
JMC 3274 Entrepreneurship in Media Dr. Yong Eric Mbarika Hall
WEDNESDAY
TIME COURSE LECTURER HALL
14:00 – 17:00
BMS 1232 Knowledge Leadership & African Dev. Grp 2 Dr. Ndah Grimbald J-E. Pondi Hall
ICT 2220 OO Analysis, Design & Implementation Grp 2 Engr. Palma George Mbarika Hall
CSC 3221 Intro to Data Science Grp 1 Dr. Fotsing BS Chumbow Hall
BNF 2222 Risk Management Mr. Njabe Charles Terry & Linda Byrd Hall
JMC 3276 Sociology & Psychology in Media Dr. Yong IT Hall
THURSDAY
TIME COURSE LECTURER HALL
8:00 – 11:00
ICT 2231 Operating Systems Grp 1 Engr. Tanwi George Mbarika Hall
JMC 2271 Mobile App Dev. for Journalists Dr. Nkandeu IT Hall
ACC 1213 Principles of Accounting 2 Mgr. Ayuk Collins BS Chumbow Hall
ECN 2243 Statistics for Business & Economics Mr. Ekane Lesley Terry & Linda Byrd Hall
ICT 3212 Advanced Database Systems Engr. Moune J-E. Pondi Hall
ISN 3231 Network Management Engr. Nebasi Eric Mbarika Hall
JMC 3273 Research Methods in Media Mme Tita Radio & TV Unit
11:00 – 14:00
CSC 1121 Research Methodology for CS Engineers Grp 2 Dr. Fotsing J-E. Pondi Hall
CYS 3251 Network/Computer Forensics Engr. Nebasi BS Chumbow Hall
BNF 3226 Financial Institutions and Instruments Mr. Ekane Lesley Eric Mbarika Hall
ICT 2231 Operating Systems Grp 2 Engr. Tanwi George Mbarika Hall
JMC 3272 Cyber Journalism Mme Tita IT Hall
14:00 – 17:00
JMC 2273 Radio and TV Programme Writing Mme Tita Eric Mbarika Hall
EGL 1262 Communication Skills Mme Bambot Delphine J-E. Pondi Hall
BNF 4229 Financial Management Ms. Tarbot Chelsea BS Chumbow Hall
ACC 3219 Advanced Accounting Info System/Accounting Lab Mgr. Ayuk Collins Terry & Linda Byrd Hall
ISN 2231 Computer Networking and Security Engr. Nebasi IT Hall
SEN 3243 Advanced Web Development Grp 1 Engr. Tanwi George Mbarika Hall
FRIDAY
TIME COURSE LECTURER HALL
7:00 – 9:00
SPT 1200 Sports and Physical Education Mr. Mounbeket Olembe Sports Complex
ACC 4212 Advanced Financial Accounting Mme Atemlefeh Vanessa Terry & Linda Byrd Hall
MTH 1245 Discrete Mathematics Grp 2 Dr. Keyampi George Mbarika Hall
REN 3261 Hydrogen and Fuel Cells Engr. Ridley BS Chumbow Hall
JMC 2275 Digital Radio Production II Mr. Betangacho Radio & TV Unit
ICT 1220 Intro to Networking Grp 1 Engr. Mughe J-E. Pondi Hall
BMS 3233 Business Law Mr. Njabe Charles IT Hall
ICT 3211 IT Infrastructure Management Dr. Fosso Eric Mbarika Hall
11:00 – 14:00
ACC 3218 Fraud and Ethics Ms. Tarbot Chelsea IT Hall
MTH 1245 Discrete Mathematics Grp 1 Dr. Keyampi J-E. Pondi Hall
ICT 1222 Algorithms & Data Structures II Grp 2 Engr. Mughe George Mbarika Hall
REN 3263 Sustainable Energy Management & Climate Change Engr. Ridley Terry & Linda Byrd Hall
JMC 2274 Digital TV Production II Mr. Betangacho Eric Mbarika Hall
14:00 – 17:00
ACC 4213 OHADA Accounting II Mgr. Ayuk Collins Terry & Linda Byrd Hall
ICT 2220 OO Analysis, Design & Implementation Grp 1 Engr. Palma George Mbarika Hall
SATURDAY
TIME COURSE LECTURER HALL
8:00 – 11:00 BMS 2238 Introduction to E-Commerce Engr. Palma George Mbarika Hall
"""

halls = ["Terry & Linda Byrd Hall", "BS Chumbow Hall", "J-E. Pondi Hall", "George Mbarika Hall", "IT Hall", "Eric Mbarika Hall", "Radio & TV Unit", "Sports Complex"]
titles = ["Mr.", "Dr.", "Engr.", "Mgr.", "Mme", "Ms.", "Prof."]

lines = raw_data.split('\n')
current_day = ""
current_time = ""

entries = []

for line in lines:
    line = line.strip()
    if not line:
        continue
    if line in ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]:
        current_day = line.capitalize()
        continue
    if line.startswith("TIME COURSE") or "SPRING" in line or "English Speaking" in line:
        continue
        
    # Check if line is a time
    time_match = re.match(r"(\d{1,2}:\d{2})\s*–\s*(\d{1,2}:\d{2})", line)
    if time_match:
        current_time = f"{time_match.group(1)} - {time_match.group(2)}"
        # Sometimes there's a course on the same line as time, e.g., SATURDAY
        remaining_line = line[time_match.end():].strip()
        if not remaining_line:
            continue
        line = remaining_line
    
    # Process course line
    # Find hall
    found_hall = ""
    for hall in halls:
        if line.endswith(hall):
            found_hall = hall
            line = line[:-len(hall)].strip()
            break
            
    # Find lecturer
    # We look for the last occurrence of any title
    last_title_idx = -1
    for title in titles:
        idx = line.rfind(title)
        if idx > last_title_idx:
            last_title_idx = idx
            
    if last_title_idx != -1:
        lecturer = line[last_title_idx:].strip()
        course = line[:last_title_idx].strip()
    else:
        print("ERROR processing line:", line)
        continue
        
    entries.append({
        "day": current_day,
        "time": current_time,
        "course": course,
        "lecturer": lecturer,
        "hall": found_hall
    })

with open('prisma/timetable.json', 'w', encoding='utf-8') as f:
    json.dump(entries, f, indent=2)
