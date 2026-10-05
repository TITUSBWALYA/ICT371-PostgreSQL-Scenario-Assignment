---------Create events

CREATE TABLE events (
    event_id SERIAL PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    event_date DATE NOT NULL,
    total_seats INTEGER NOT NULL,
    available_seats INTEGER NOT NULL
);


--------Check the table

SELECT * FROM events;


----------Create bookings

CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL,
    student_name VARCHAR(100) NOT NULL,
    student_number VARCHAR(50) NOT NULL,
    seats_booked INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL
);

--------Add the foreign key

ALTER TABLE bookings
ADD CONSTRAINT fk_event
FOREIGN KEY (event_id)
REFERENCES events(event_id);

--------Insert three events

INSERT INTO events
(event_name, event_date, total_seats, available_seats)
VALUES
('ICT Conference', '2026-10-10', 100, 100),
('Computer Science Seminar', '2026-10-11', 50, 50),
('Programming Workshop', '2026-10-12', 30, 30);



---------check output
SELECT * FROM events
ORDER BY event_id;

SELECT * FROM bookings
ORDER BY booking_id;


-------IF / ELSIF / ELSE
DO $$
DECLARE
    event_record RECORD;
BEGIN

    FOR event_record IN
        SELECT event_id,
               event_name,
               available_seats
        FROM events
        ORDER BY event_id
    LOOP

        IF event_record.available_seats = 0 THEN

            RAISE NOTICE
                'Event %: FULL - No seats available.',
                event_record.event_name;

        ELSIF event_record.available_seats <= 5 THEN

            RAISE NOTICE
                'Event %: NEARLY FULL - Only % seat(s) available.',
                event_record.event_name,
                event_record.available_seats;

        ELSE

            RAISE NOTICE
                'Event %: SEATS AVAILABLE - % seats remaining.',
                event_record.event_name,
                event_record.available_seats;

        END IF;

    END LOOP;

END $$;



-------Temporary test for nearly full
UPDATE events
SET available_seats = 5
WHERE event_id = 2;

-------Temporary test for full
UPDATE events
SET available_seats = 0
WHERE event_id = 2;

---------Restore Event 2
UPDATE events
SET available_seats = 50
WHERE event_id = 2;

-------WHILE loop

DO $$
DECLARE
    reminder_number INTEGER := 1;
BEGIN

    WHILE reminder_number <= 3 LOOP

        RAISE NOTICE
            'Event Preparation Reminder %: Prepare the venue and seating.',
            reminder_number;

        reminder_number := reminder_number + 1;

    END LOOP;

END $$;



----------Numeric FOR loop

DO $$
BEGIN

    FOR check_number IN 1..3 LOOP

        RAISE NOTICE
            'Seat Availability Check %: Check available event seats.',
            check_number;

    END LOOP;

END $$;



---------CREATE book_seats PROCEDURE

CREATE OR REPLACE PROCEDURE book_seats(
    p_event_id INTEGER,
    p_student_name VARCHAR,
    p_student_number VARCHAR,
    p_seats INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_seats INTEGER;
BEGIN

    IF p_seats <= 0 THEN

        RAISE EXCEPTION
            'Invalid number of seats: %. Seats must be greater than zero.',
            p_seats;

    END IF;


    SELECT available_seats
    INTO current_seats
    FROM events
    WHERE event_id = p_event_id;


    IF NOT FOUND THEN

        RAISE EXCEPTION
            'Event ID % does not exist.',
            p_event_id;

    END IF;


    IF p_seats > current_seats THEN

        RAISE NOTICE
            'Booking rejected. Requested: %, Available: %.',
            p_seats,
            current_seats;

        RETURN;

    END IF;


    UPDATE events
    SET available_seats = available_seats - p_seats
    WHERE event_id = p_event_id;


    INSERT INTO bookings
    (
        event_id,
        student_name,
        student_number,
        seats_booked,
        status
    )
    VALUES
    (
        p_event_id,
        p_student_name,
        p_student_number,
        p_seats,
        'Booked'
    );


    RAISE NOTICE
        'Booking successful for %. Seats booked: %.',
        p_student_name,
        p_seats;

END;


--------First valid booking
CALL book_seats(
    1,
    'Titus Bwalya',
    '2023843',
    10
);

-------second valid booking
CALL book_seats(
    2,
    'John Phiri',
    '2023123',
    15
);


-------Third valid booking

CALL book_seats(
    3,
    'Peter Mwansa',
    '2023789',
    25
);


------Verify
SELECT * FROM events
ORDER BY event_id;

SELECT * FROM bookings
ORDER BY booking_id;


----------CREATE cancel_booking PROCEDURE

CREATE OR REPLACE PROCEDURE cancel_booking(
    p_booking_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    booking_event INTEGER;
    booked_seats INTEGER;
    booking_status VARCHAR(20);
BEGIN

    SELECT event_id,
           seats_booked,
           status
    INTO booking_event,
         booked_seats,
         booking_status
    FROM bookings
    WHERE booking_id = p_booking_id;


    IF NOT FOUND THEN

        RAISE EXCEPTION
            'Booking ID % does not exist.',
            p_booking_id;

    END IF;


    IF booking_status = 'Booked' THEN

        UPDATE events
        SET available_seats =
            available_seats + booked_seats
        WHERE event_id = booking_event;


        UPDATE bookings
        SET status = 'Cancelled'
        WHERE booking_id = p_booking_id;


        RAISE NOTICE
            'Booking % cancelled. % seat(s) released.',
            p_booking_id,
            booked_seats;

    ELSE

        RAISE NOTICE
            'Booking % is already cancelled. No seats released.',
            p_booking_id;

    END IF;

END;
$$;


--------Cancel the first booking
CALL cancel_booking(1);

-------Cancel it again
CALL cancel_booking(1);

-----check results
SELECT * FROM events
ORDER BY event_id;

SELECT * FROM bookings
ORDER BY booking_id;



----------EXPLICIT CURSOR
DO $$
DECLARE
    event_cursor CURSOR FOR
        SELECT event_id,
               event_name,
               available_seats
        FROM events
        WHERE available_seats <= 5;

    event_record RECORD;
BEGIN

    OPEN event_cursor;


    LOOP

        FETCH event_cursor
        INTO event_record;


        EXIT WHEN NOT FOUND;


        RAISE NOTICE
            'Low seat availability - Event: %, Seats remaining: %',
            event_record.event_name,
            event_record.available_seats;

    END LOOP;


    CLOSE event_cursor;

END $$;



-------EXCEPTION FOR ZERO SEATS

DO $$
BEGIN

    BEGIN

        CALL book_seats(
            3,
            'Peter Mwansa',
            '2023789',
            0
        );


    EXCEPTION
        WHEN OTHERS THEN

            RAISE NOTICE
                'EXCEPTION HANDLED: %',
                SQLERRM;

    END;

END $$;




-------Final events

SELECT
    event_id,
    event_name,
    event_date,
    total_seats,
    available_seats
FROM events
ORDER BY event_id;



---------Final bookings
SELECT
    booking_id,
    event_id,
    student_name,
    student_number,
    seats_booked,
    status
FROM bookings
ORDER BY booking_id;