-- =====================================================
-- PART 1: DATABASE CREATION AND TABLE DEFINITIONS (PostgreSQL Compatible)
-- =====================================================

-- Drop tables if they exist (in reverse order of dependencies)
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS activity_review;
DROP TABLE IF EXISTS host_Review;
DROP TABLE IF EXISTS Booking;
DROP TABLE IF EXISTS Verification;
DROP TABLE IF EXISTS Experiences;
DROP TABLE IF EXISTS Activity;
DROP TABLE IF EXISTS Tourist;
DROP TABLE IF EXISTS Host;
DROP TABLE IF EXISTS Admin;
DROP TABLE IF EXISTS UserAccount; 

-- Create UserAccount table
CREATE TABLE UserAccount (
    User_id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    user_password VARCHAR(255) NOT NULL,
    user_email VARCHAR(255) NOT NULL UNIQUE,
    userType VARCHAR(20) NOT NULL CHECK (userType IN ('Admin', 'Host', 'Tourist')),
    user_DateOfCreation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Admin table
CREATE TABLE Admin (
    admin_id INT PRIMARY KEY,
    adm_code VARCHAR(50) NOT NULL UNIQUE,
    FOREIGN KEY (admin_id) REFERENCES UserAccount(User_id) ON DELETE CASCADE
);

-- Create Host table
CREATE TABLE Host (
    host_id INT PRIMARY KEY,
    hos_description TEXT,
    hos_DateSubmission TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    hos_cv VARCHAR(255),
    hos_cin VARCHAR(50),
    hos_tel VARCHAR(20),
    FOREIGN KEY (host_id) REFERENCES UserAccount(User_id) ON DELETE CASCADE
);

-- Create Tourist table
CREATE TABLE Tourist (
    tourist_id INT PRIMARY KEY,
    Trs_originalCountry VARCHAR(100),
    Trs_age INT CHECK (Trs_age >= 0),
    Trs_emergencyContact VARCHAR(100),
    Trs_ActivityCount INT DEFAULT 0,
    FOREIGN KEY (tourist_id) REFERENCES UserAccount(User_id) ON DELETE CASCADE
);

-- Create Activity table
CREATE TABLE Activity (
    activity_id SERIAL PRIMARY KEY,
    act_title VARCHAR(255) NOT NULL,
    act_description TEXT,
    act_image VARCHAR(255),
    act_location VARCHAR(255),
    act_date DATE,
    act_time TIME,
    act_capacity INT CHECK (act_capacity > 0),
    act_available_seats INT CHECK (act_available_seats >= 0),
    act_status VARCHAR(20) DEFAULT 'Active' CHECK (act_status IN ('Active', 'Inactive', 'Cancelled')),
    host_id INT NOT NULL,
    FOREIGN KEY (host_id) REFERENCES Host(host_id) ON DELETE CASCADE,
    CHECK (act_available_seats <= act_capacity)
);

-- Create Booking table
CREATE TABLE Booking (
    booking_id SERIAL PRIMARY KEY,
    activity_id INT NOT NULL,
    tourist_id INT NOT NULL,
    bkg_Date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    bkg_Status VARCHAR(20) DEFAULT 'Pending' CHECK (bkg_Status IN ('Pending', 'Confirmed', 'Cancelled', 'Completed')),
    bkg_spotsReserved INT NOT NULL CHECK (bkg_spotsReserved > 0),
    FOREIGN KEY (activity_id) REFERENCES Activity(activity_id) ON DELETE CASCADE,
    FOREIGN KEY (tourist_id) REFERENCES Tourist(tourist_id) ON DELETE CASCADE
);

-- Create Payment table
CREATE TABLE Payment (
    payment_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL UNIQUE,
    payTotalAmount DECIMAL(10, 2) NOT NULL CHECK (payTotalAmount >= 0),
    paymentMethod VARCHAR(50) NOT NULL CHECK (paymentMethod IN ('Credit Card', 'Debit Card', 'PayPal', 'Cash')),
    paymentStatus VARCHAR(20) DEFAULT 'Pending' CHECK (paymentStatus IN ('Pending', 'Completed', 'Failed', 'Refunded')),
    tourist_id INT NOT NULL,
    FOREIGN KEY (booking_id) REFERENCES Booking(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (tourist_id) REFERENCES Tourist(tourist_id) ON DELETE CASCADE
);

-- Create Verification table
CREATE TABLE Verification (
    verification_id SERIAL PRIMARY KEY,
    Host_id INT NOT NULL,
    ver_Date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ver_Status VARCHAR(20) DEFAULT 'Pending' CHECK (ver_Status IN ('Pending', 'Approved', 'Rejected')),
    admin_id INT NOT NULL,
    FOREIGN KEY (Host_id) REFERENCES Host(host_id) ON DELETE CASCADE,
    FOREIGN KEY (admin_id) REFERENCES Admin(admin_id) ON DELETE CASCADE
);

-- Create Experiences table (junction table for Admin and Activity)
CREATE TABLE Experiences (
    admin_id INT NOT NULL,
    activity_id INT NOT NULL,
    PRIMARY KEY (admin_id, activity_id),
    FOREIGN KEY (admin_id) REFERENCES Admin(admin_id) ON DELETE CASCADE,
    FOREIGN KEY (activity_id) REFERENCES Activity(activity_id) ON DELETE CASCADE
);

-- Create host_Review table
CREATE TABLE host_Review (
    host_id INT NOT NULL,
    tourist_id INT NOT NULL,
    hos_rating DECIMAL(2, 1) CHECK (hos_rating >= 0 AND hos_rating <= 5),
    Trs_comment TEXT,
    PRIMARY KEY (host_id, tourist_id),
    FOREIGN KEY (host_id) REFERENCES Host(host_id) ON DELETE CASCADE,
    FOREIGN KEY (tourist_id) REFERENCES Tourist(tourist_id) ON DELETE CASCADE
);

-- Create activity_review table
CREATE TABLE activity_review (
    tourist_id INT NOT NULL,
    activity_id INT NOT NULL,
    rev_text TEXT,
    rev_activityRating DECIMAL(2, 1) CHECK (rev_activityRating >= 0 AND rev_activityRating <= 5),
    rev_hostRating DECIMAL(2, 1) CHECK (rev_hostRating >= 0 AND rev_hostRating <= 5),
    rev_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (tourist_id, activity_id),
    FOREIGN KEY (tourist_id) REFERENCES Tourist(tourist_id) ON DELETE CASCADE,
    FOREIGN KEY (activity_id) REFERENCES Activity(activity_id) ON DELETE CASCADE
);

-- =====================================================
-- PART 2: DATABASE POPULATION
-- =====================================================

-- Insert UserAccounts
INSERT INTO UserAccount (username, user_password, user_email, userType) VALUES
('admin_john', 'hashed_pwd_123', 'john.admin@tourism.com', 'Admin'),
('admin_sarah', 'hashed_pwd_456', 'sarah.admin@tourism.com', 'Admin'),
('host_ahmed', 'hashed_pwd_789', 'ahmed.host@tourism.com', 'Host'),
('host_fatima', 'hashed_pwd_101', 'fatima.host@tourism.com', 'Host'),
('host_youssef', 'hashed_pwd_102', 'youssef.host@tourism.com', 'Host'),
('tourist_emily', 'hashed_pwd_103', 'emily.tourist@gmail.com', 'Tourist'),
('tourist_david', 'hashed_pwd_104', 'david.tourist@gmail.com', 'Tourist'),
('tourist_maria', 'hashed_pwd_105', 'maria.tourist@gmail.com', 'Tourist'),
('tourist_james', 'hashed_pwd_106', 'james.tourist@gmail.com', 'Tourist'),
('tourist_sophia', 'hashed_pwd_107', 'sophia.tourist@gmail.com', 'Tourist');

-- Insert Admins (IDs must match UserAccount)
INSERT INTO Admin (admin_id, adm_code) VALUES
(1, 'ADM001'),
(2, 'ADM002');

-- Insert Hosts
INSERT INTO Host (host_id, hos_description, hos_cv, hos_cin, hos_tel) VALUES
(3, 'Experienced tour guide specializing in cultural tours', 'cv_ahmed.pdf', 'CIN123456', '+212600111111'),
(4, 'Adventure activities expert with 5 years experience', 'cv_fatima.pdf', 'CIN234567', '+212600222222'),
(5, 'Local historian and heritage tour specialist', 'cv_youssef.pdf', 'CIN345678', '+212600333333');

-- Insert Tourists
INSERT INTO Tourist (tourist_id, Trs_originalCountry, Trs_age, Trs_emergencyContact, Trs_ActivityCount) VALUES
(6, 'USA', 28, '+1234567890', 0),
(7, 'UK', 35, '+4412345678', 0),
(8, 'Spain', 26, '+34612345678', 0),
(9, 'France', 42, '+33612345678', 0),
(10, 'Germany', 31, '+49123456789', 0);

-- Insert Activities
INSERT INTO Activity (act_title, act_description, act_image, act_location, act_date, act_time, act_capacity, act_available_seats, act_status, host_id) VALUES
('Fes Medina Walking Tour', 'Explore the ancient medina of Fes with local guides', 'fes_tour.jpg', 'Fes', '2025-01-15', '09:00:00', 15, 15, 'Active', 3),
('Atlas Mountain Hiking', 'Day hike through beautiful Atlas Mountains', 'atlas_hike.jpg', 'Atlas Mountains', '2025-01-20', '07:00:00', 10, 10, 'Active', 4),
('Moroccan Cooking Class', 'Learn to cook traditional Moroccan dishes', 'cooking.jpg', 'Marrakech', '2025-01-18', '14:00:00', 8, 8, 'Active', 3),
('Sahara Desert Safari', '2-day camel trek in Sahara Desert', 'sahara.jpg', 'Merzouga', '2025-01-25', '06:00:00', 12, 12, 'Active', 4),
('Chefchaouen Blue City Tour', 'Visit the famous blue city', 'chefchaouen.jpg', 'Chefchaouen', '2025-02-01', '10:00:00', 20, 20, 'Active', 5),
('Casablanca City Tour', 'Modern and historical Casablanca', 'casablanca.jpg', 'Casablanca', '2025-02-05', '09:30:00', 15, 15, 'Active', 5);

-- Insert Verifications
INSERT INTO Verification (Host_id, ver_Status, admin_id) VALUES
(3, 'Approved', 1),
(4, 'Approved', 1),
(5, 'Pending', 2);

-- Insert Bookings
INSERT INTO Booking (activity_id, tourist_id, bkg_Status, bkg_spotsReserved) VALUES
(1, 6, 'Confirmed', 2),
(1, 7, 'Confirmed', 1),
(2, 8, 'Confirmed', 2),
(3, 6, 'Completed', 1),
(4, 9, 'Confirmed', 3),
(5, 10, 'Pending', 2),
(2, 7, 'Cancelled', 1);

-- Insert Payments
INSERT INTO Payment (booking_id, payTotalAmount, paymentMethod, paymentStatus, tourist_id) VALUES
(1, 80.00, 'Credit Card', 'Completed', 6),
(2, 40.00, 'PayPal', 'Completed', 7),
(3, 120.00, 'Credit Card', 'Completed', 8),
(4, 50.00, 'Debit Card', 'Completed', 6),
(5, 450.00, 'Credit Card', 'Completed', 9),
(6, 100.00, 'Credit Card', 'Pending', 10);

-- Insert Reviews
INSERT INTO activity_review (tourist_id, activity_id, rev_text, rev_activityRating, rev_hostRating, rev_date) VALUES
(6, 3, 'Amazing cooking experience! Learned so much.', 5.0, 5.0, '2025-01-19 16:00:00'),
(7, 1, 'Great tour but a bit crowded.', 4.0, 4.5, '2025-01-15 13:00:00'),
(8, 2, 'Breathtaking views and excellent guide.', 4.5, 5.0, '2025-01-20 18:00:00');

INSERT INTO host_Review (host_id, tourist_id, hos_rating, Trs_comment) VALUES
(3, 6, 5.0, 'Very knowledgeable and friendly host'),
(4, 8, 5.0, 'Professional and safety-conscious'),
(3, 7, 4.0, 'Good guide, very informative');

-- Insert Admin Experiences
INSERT INTO Experiences (admin_id, activity_id) VALUES
(1, 1),
(1, 2),
(2, 3),
(1, 4);

-- =====================================================
-- PART 3: VIEWS (PostgreSQL Compatible)
-- =====================================================

-- View 1: Activity Details
CREATE OR REPLACE VIEW vw_ActivityDetails AS
SELECT 
    a.activity_id,
    a.act_title,
    a.act_description,
    a.act_location,
    a.act_date,
    a.act_time,
    a.act_capacity,
    a.act_available_seats,
    a.act_status,
    u.username AS host_name,
    u.user_email AS host_email,
    h.hos_tel AS host_phone
FROM Activity a
JOIN Host h ON a.host_id = h.host_id
JOIN UserAccount u ON h.host_id = u.User_id;

-- View 2: Booking Summary
CREATE OR REPLACE VIEW vw_BookingSummary AS
SELECT 
    b.booking_id,
    b.bkg_Date,
    b.bkg_Status,
    b.bkg_spotsReserved,
    a.act_title AS activity_name,
    a.act_date AS activity_date,
    u.username AS tourist_name,
    u.user_email AS tourist_email,
    p.payTotalAmount,
    p.paymentMethod,
    p.paymentStatus
FROM Booking b
JOIN Activity a ON b.activity_id = a.activity_id
JOIN Tourist t ON b.tourist_id = t.tourist_id
JOIN UserAccount u ON t.tourist_id = u.User_id
LEFT JOIN Payment p ON b.booking_id = p.booking_id;