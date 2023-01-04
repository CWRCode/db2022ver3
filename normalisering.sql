USE iths;

DROP TABLE IF EXISTS UNF;

CREATE TABLE UNF (
        Id DECIMAL(38, 0) NOT NULL,
        Name VARCHAR(26) NOT NULL,
        Grade VARCHAR(11) NOT NULL,
        Hobbies VARCHAR(25),
        City VARCHAR(10) NOT NULL,
        School VARCHAR(30) NOT NULL,
        HomePhone VARCHAR(15),
        JobPhone VARCHAR(15),
        MobilePhone1 VARCHAR(15),
        MobilePhone2 VARCHAR(15)
) ENGINE=INNODB;

LOAD DATA INFILE '/var/lib/mysql-files/denormalized-data.csv'
INTO TABLE UNF
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

/* Normalisera Student */

DROP TABLE IF EXISTS Student;

CREATE Table Student (
	StudentId INT NOT NULL AUTO_INCREMENT,
	FirstName VARCHAR(255) NOT NULL,
	LastName VARCHAR(255) NOT NULL,
	CONSTRAINT PRIMARY KEY (StudentId)
) ENGINE=INNODB;

/* Ska denna liggar här? 
ALTER TABLE Student MODIFY COLUMN StudentId Int AUTO_INCREMENT; */

INSERT INTO Student (StudentId, FirstName, LastName)
SELECT DISTINCT Id, SUBSTRING_INDEX(Name, ' ', 1), SUBSTRING_INDEX(Name, ' ', -1)
FROM UNF;



/* Normalisera School */
DROP TABLE IF EXISTS School;
CREATE TABLE School AS SELECT DISTINCT 0 As SchoolId, School As Name, City FROM UNF;

SET @id = 0;
UPDATE School SET SchoolId =  (SELECT @id := @id + 1);

ALTER TABLE School ADD PRIMARY KEY(SchoolId);



/* Skapa kopplingstabell student-school */

DROP TABLE IF EXISTS StudentSchool;

CREATE TABLE StudentSchool AS SELECT DISTINCT UNF.Id AS StudentId, School.SchoolId
FROM UNF INNER JOIN School ON UNF.School = School.Name;
ALTER TABLE StudentSchool MODIFY COLUMN StudentId INT;
ALTER TABLE StudentSchool MODIFY COLUMN SchoolId INT;
ALTER TABLE StudentSchool ADD PRIMARY KEY(StudentId, SchoolId);

/*
-SELECT STATSER-

SELECT StudentId, FirstName, LastName FROM Student
JOIN StudentSchool USING (StudentId);

SELECT StudentId, FirstName, LastName, Name, City FROM Student
JOIN StudentSchool USING (StudentId) 
JOIN School USING (SchoolId);
*/



/* Normalisera PhoneBook */

DROP TABLE IF EXISTS Phone;
CREATE TABLE Phone (
    PhoneId INT NOT NULL AUTO_INCREMENT,
    StudentId INT NOT NULL,
    Type VARCHAR(32),
    Number VARCHAR(32) NOT NULL,
    CONSTRAINT PRIMARY KEY(PhoneId)
);

INSERT INTO Phone(StudentId, Type, Number) 
SELECT Id As StudentId, "Home" AS Type, HomePhone as Number FROM UNF
WHERE HomePhone IS NOT NULL AND HomePhone != ''
UNION SELECT Id As StudentId, "Job" AS Type, JobPhone as Number FROM UNF
WHERE JobPhone IS NOT NULL AND JobPhone != ''
UNION SELECT Id As StudentId, "Mobile" AS Type, MobilePhone1 as Number FROM UNF
WHERE MobilePhone1 IS NOT NULL AND MobilePhone1 != ''
UNION SELECT Id As StudentId, "Mobile2" AS Type, MobilePhone2 as Number FROM UNF
WHERE MobilePhone2 IS NOT NULL AND MobilePhone2 != ''
;

DROP VIEW IF EXISTS PhoneList;
CREATE VIEW PhoneList AS SELECT StudentId, group_concat(Number) AS Numbers FROM Phone GROUP BY StudentId;


/*
-SELECT SATS-
SELECT FirstName, LastName, Numbers from Student JOIN PhoneList USING (StudentId);
*/


/* Normalisering Hobbies 
påminner om school?? 

*/

DROP TABLE IF EXISTS Hobbies;
CREATE TABLE Hobbies AS SELECT DISTINCT 0 As HobbyId, trim(SUBSTRING_INDEX(Hobbies, ",", 1)) AS Hobby FROM UNF WHERE Hobbies IS NOT NULL AND Hobbies != ''
UNION SELECT DISTINCT 0 As HobbyId, trim(substring_index(substring_index(Hobbies, ",", -2),"," ,1)) AS Hobby FROM UNF
WHERE Hobbies IS NOT NULL AND Hobbies != ''
UNION SELECT DISTINCT 0 As HobbyId, trim(substring_index(Hobbies, ",", -1)) AS Hobby FROM UNF
WHERE Hobbies IS NOT NULL AND Hobbies != ''
;

SET @id = 0;
UPDATE Hobbies SET HobbyId =  (SELECT @id := @id + 1);

ALTER TABLE Hobbies ADD PRIMARY KEY(HobbyId);


/* TABLE */
DROP TABLE IF EXISTS StudentHobbies;

CREATE TABLE StudentHobbies AS SELECT DISTINCT UNF.Id AS StudentId, Hobbies.HobbyId
FROM UNF INNER JOIN Hobbies ON UNF.Hobbies = Hobbies.Hobby;
ALTER TABLE StudentHobbies MODIFY COLUMN StudentId INT;
ALTER TABLE StudentHobbies MODIFY COLUMN HobbyId INT;
ALTER TABLE StudentHobbies ADD PRIMARY KEY(StudentId, HobbyId);



/*

DROP TABLE IF EXISTS Hobbies;
CREATE TABLE Hobbies (
    HobbyId INT NOT NULL AUTO_INCREMENT,
    StudentId INT NOT NULL,
    Type VARCHAR(32),
    Hobby VARCHAR(64) NOT NULL,
    CONSTRAINT PRIMARY KEY(HobbyId)
);


INSERT INTO Hobbies(StudentId, Type, Hobby)
SELECT Id As StudentId, "first" AS Type, trim(SUBSTRING_INDEX(Hobbies, ",", 1)) AS Hobby FROM UNF
WHERE Hobbies IS NOT NULL AND Hobbies != ''
UNION SELECT Id As StudentId, "second" AS Type, trim(substring_index(substring_index(Hobbies, ",", -2),"," ,1)) AS Hobby FROM UNF
WHERE Hobbies IS NOT NULL AND Hobbies != ''
UNION SELECT Id As StudentId, "third" AS Type, trim(substring_index(Hobbies, ",", -1)) AS Hobby FROM UNF
WHERE Hobbies IS NOT NULL AND Hobbies != ''
;



DROP VIEW IF EXISTS StudentHobbies;
CREATE VIEW StudentHobbies AS SELECT StudentId, group_concat(Hobby) AS Hobby FROM Hobbies GROUP BY StudentId;

*/

/* Normalisering Betyg */

/* Normalisering Grade ??? */
