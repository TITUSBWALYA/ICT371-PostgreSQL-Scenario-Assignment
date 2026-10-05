-- TASK 1: CREATE LAB_SESSIONS TABLE

CREATE TABLE lab_sessions (
    session_id SERIAL PRIMARY KEY,
    session_name VARCHAR(100) NOT NULL,
    session_date DATE NOT NULL,
    available_workstations INTEGER NOT NULL
);

SELECT * FROM lab_sessions;


-- TASK 1: CREATE RESERVATIONS TABLE

CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL,
    lecturer VARCHAR(100) NOT NULL,
    workstations INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL
);


-- TASK 1: ADD FOREIGN KEY

ALTER TABLE reservations
ADD CONSTRAINT fk_session
FOREIGN KEY (session_id)
REFERENCES lab_sessions(session_id);


-- TASK 1: INSERT THREE LAB SESSIONS

INSERT INTO lab_sessions
(session_name, session_date, available_workstations)
VALUES
('Database Practical', '2026-10-06', 30),
('Networking Practical', '2026-10-07', 20),
('Programming Practical', '2026-10-08', 15);

SELECT * FROM lab_sessions;
SELECT * FROM reservations;


-- TASK 2: IF / ELSIF / ELSE

DO $$
DECLARE
    session_record RECORD;
BEGIN
    FOR session_record IN
        SELECT session_id,
               session_name,
               available_workstations
        FROM lab_sessions
        ORDER BY session_id
    LOOP
        IF session_record.available_workstations = 0 THEN
            RAISE NOTICE
                'Session % (%): FULL - No workstations available.',
                session_record.session_id,
                session_record.session_name;

        ELSIF session_record.available_workstations <= 5 THEN
            RAISE NOTICE
                'Session % (%): NEARLY FULL - Only % workstation(s) available.',
                session_record.session_id,
                session_record.session_name,
                session_record.available_workstations;

        ELSE
            RAISE NOTICE
                'Session % (%): ENOUGH WORKSTATIONS - % available.',
                session_record.session_id,
                session_record.session_name,
                session_record.available_workstations;
        END IF;
    END LOOP;
END $$;


-- TASK 2: TEMPORARY TEST FOR NEARLY FULL

UPDATE lab_sessions
SET available_workstations = 4
WHERE session_id = 2;

DO $$
DECLARE
    session_record RECORD;
BEGIN
    FOR session_record IN
        SELECT session_id,
               session_name,
               available_workstations
        FROM lab_sessions
        ORDER BY session_id
    LOOP
        IF session_record.available_workstations = 0 THEN
            RAISE NOTICE
                'Session % (%): FULL - No workstations available.',
                session_record.session_id,
                session_record.session_name;

        ELSIF session_record.available_workstations <= 5 THEN
            RAISE NOTICE
                'Session % (%): NEARLY FULL - Only % workstation(s) available.',
                session_record.session_id,
                session_record.session_name,
                session_record.available_workstations;

        ELSE
            RAISE NOTICE
                'Session % (%): ENOUGH WORKSTATIONS - % available.',
                session_record.session_id,
                session_record.session_name,
                session_record.available_workstations;
        END IF;
    END LOOP;
END $$;


-- TASK 2: TEMPORARY TEST FOR FULL

UPDATE lab_sessions
SET available_workstations = 0
WHERE session_id = 2;

DO $$
DECLARE
    session_record RECORD;
BEGIN
    FOR session_record IN
        SELECT session_id,
               session_name,
               available_workstations
        FROM lab_sessions
        ORDER BY session_id
    LOOP
        IF session_record.available_workstations = 0 THEN
            RAISE NOTICE
                'Session % (%): FULL - No workstations available.',
                session_record.session_id,
                session_record.session_name;

        ELSIF session_record.available_workstations <= 5 THEN
            RAISE NOTICE
                'Session % (%): NEARLY FULL - Only % workstation(s) available.',
                session_record.session_id,
                session_record.session_name,
                session_record.available_workstations;

        ELSE
            RAISE NOTICE
                'Session % (%): ENOUGH WORKSTATIONS - % available.',
                session_record.session_id,
                session_record.session_name,
                session_record.available_workstations;
        END IF;
    END LOOP;
END $$;


-- RESTORE SESSION 2

UPDATE lab_sessions
SET available_workstations = 20
WHERE session_id = 2;


-- TASK 3: WHILE LOOP

DO $$
DECLARE
    reminder_number INTEGER := 1;
BEGIN
    WHILE reminder_number <= 3 LOOP
        RAISE NOTICE
            'Session Preparation Reminder %: Prepare the computer laboratory.',
            reminder_number;

        reminder_number := reminder_number + 1;
    END LOOP;
END $$;


-- TASK 3: NUMERIC FOR LOOP

DO $$
BEGIN
    FOR check_number IN 1..3 LOOP
        RAISE NOTICE
            'Workstation Check %: Check workstation availability.',
            check_number;
    END LOOP;
END $$;


-- TASK 4: RESERVE_WORKSTATIONS PROCEDURE

CREATE OR REPLACE PROCEDURE reserve_workstations(
    p_session_id INTEGER,
    p_lecturer VARCHAR,
    p_workstations INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_availability INTEGER;
BEGIN
    IF p_workstations <= 0 THEN
        RAISE EXCEPTION
            'Invalid number of workstations: %. Quantity must be greater than zero.',
            p_workstations;
    END IF;

    SELECT available_workstations
    INTO current_availability
    FROM lab_sessions
    WHERE session_id = p_session_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Session ID % does not exist.',
            p_session_id;
    END IF;

    IF p_workstations > current_availability THEN
        RAISE NOTICE
            'Reservation rejected. Requested: %, Available: %.',
            p_workstations,
            current_availability;

        RETURN;
    END IF;

    UPDATE lab_sessions
    SET available_workstations =
        available_workstations - p_workstations
    WHERE session_id = p_session_id;

    INSERT INTO reservations
    (session_id, lecturer, workstations, status)
    VALUES
    (p_session_id, p_lecturer, p_workstations, 'Reserved');

    RAISE NOTICE
        'Reservation successful for %. Workstations reserved: %.',
        p_lecturer,
        p_workstations;
END;
$$;


-- TASK 5: FIRST VALID RESERVATION

CALL reserve_workstations(
    1,
    'Dr. Banda',
    10
);


-- TASK 5: SECOND VALID RESERVATION

CALL reserve_workstations(
    2,
    'Mr. Phiri',
    10
);


-- TASK 5: EXCEEDING CAPACITY

CALL reserve_workstations(
    2,
    'Ms. Mulenga',
    15
);


-- TASK 5: CHECK RESULTS

SELECT * FROM lab_sessions
ORDER BY session_id;

SELECT * FROM reservations
ORDER BY reservation_id;


-- TASK 6: CANCEL_RESERVATION PROCEDURE

CREATE OR REPLACE PROCEDURE cancel_reservation(
    p_reservation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    reservation_session INTEGER;
    reserved_workstations INTEGER;
    reservation_status VARCHAR(20);
BEGIN
    SELECT session_id,
           workstations,
           status
    INTO reservation_session,
         reserved_workstations,
         reservation_status
    FROM reservations
    WHERE reservation_id = p_reservation_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Reservation ID % does not exist.',
            p_reservation_id;
    END IF;

    IF reservation_status = 'Reserved' THEN

        UPDATE lab_sessions
        SET available_workstations =
            available_workstations + reserved_workstations
        WHERE session_id = reservation_session;

        UPDATE reservations
        SET status = 'Cancelled'
        WHERE reservation_id = p_reservation_id;

        RAISE NOTICE
            'Reservation % cancelled. % workstation(s) released.',
            p_reservation_id,
            reserved_workstations;

    ELSE

        RAISE NOTICE
            'Reservation % is already cancelled. No workstations released.',
            p_reservation_id;

    END IF;
END;
$$;


-- TASK 6: FIRST CANCELLATION

CALL cancel_reservation(1);


-- TASK 6: SECOND CANCELLATION

CALL cancel_reservation(1);


-- TASK 6: CHECK CANCELLATION RESULTS

SELECT * FROM lab_sessions
ORDER BY session_id;

SELECT * FROM reservations
ORDER BY reservation_id;


-- TASK 7: EXPLICIT CURSOR

DO $$
DECLARE
    session_cursor CURSOR FOR
        SELECT session_id,
               session_name,
               available_workstations
        FROM lab_sessions
        WHERE available_workstations <= 5;

    session_record RECORD;
BEGIN
    OPEN session_cursor;

    LOOP
        FETCH session_cursor
        INTO session_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Low availability - Session ID: %, Session: %, Workstations remaining: %',
            session_record.session_id,
            session_record.session_name,
            session_record.available_workstations;
    END LOOP;

    CLOSE session_cursor;
END $$;


-- TASK 7: TEMPORARY CURSOR TEST

UPDATE lab_sessions
SET available_workstations = 4
WHERE session_id = 2;

DO $$
DECLARE
    session_cursor CURSOR FOR
        SELECT session_id,
               session_name,
               available_workstations
        FROM lab_sessions
        WHERE available_workstations <= 5;

    session_record RECORD;
BEGIN
    OPEN session_cursor;

    LOOP
        FETCH session_cursor
        INTO session_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Low availability - Session ID: %, Session: %, Workstations remaining: %',
            session_record.session_id,
            session_record.session_name,
            session_record.available_workstations;
    END LOOP;

    CLOSE session_cursor;
END $$;


-- RESTORE SESSION 2 AFTER CURSOR TEST

UPDATE lab_sessions
SET available_workstations = 10
WHERE session_id = 2;


-- TASK 8: EXCEPTION HANDLING FOR ZERO WORKSTATIONS

DO $$
BEGIN
    BEGIN
        CALL reserve_workstations(
            3,
            'Dr. Zero',
            0
        );

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE
                'EXCEPTION HANDLED: %',
                SQLERRM;
    END;
END $$;


-- TASK 9: FINAL LAB SESSION QUERY

SELECT
    session_id,
    session_name,
    session_date,
    available_workstations
FROM lab_sessions
ORDER BY session_id;


-- TASK 9: FINAL RESERVATIONS QUERY

SELECT
    reservation_id,
    session_id,
    lecturer,
    workstations,
    status
FROM reservations
ORDER BY reservation_id;