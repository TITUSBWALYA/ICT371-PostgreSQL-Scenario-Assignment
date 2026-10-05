CREATE TABLE hostel_rooms (
    room_id SERIAL PRIMARY KEY,
    hostel_name VARCHAR(100) NOT NULL,
    room_number VARCHAR(20) NOT NULL,
    capacity INTEGER NOT NULL,
    available_beds INTEGER NOT NULL
);



---------Check the table
SELECT * FROM hostel_rooms;



------Create allocations
CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    room_id INTEGER NOT NULL,
    student_name VARCHAR(100) NOT NULL,
    student_number VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL
);


---------Create allocations
ALTER TABLE allocations
ADD CONSTRAINT fk_room
FOREIGN KEY (room_id)
REFERENCES hostel_rooms(room_id);




--------Create allocations
INSERT INTO hostel_rooms
(hostel_name, room_number, capacity, available_beds)
VALUES
('Mulungushi Hostel KAPIRI', 'A101', 4, 4),
('Mulungushi Hostel LUANO', 'B201', 3, 3),
('Mulungushi Hostel KABWE', 'C301', 2, 2);




---------Verify
SELECT * FROM hostel_rooms
ORDER BY room_id;

SELECT * FROM allocations
ORDER BY allocation_id;




-------------IF / ELSIF / ELSE
DO $$
DECLARE
    room_record RECORD;
BEGIN
    FOR room_record IN
        SELECT room_id,
               room_number,
               available_beds
        FROM hostel_rooms
        ORDER BY room_id
    LOOP

        IF room_record.available_beds = 0 THEN

            RAISE NOTICE
                'Room %: FULL - No beds available.',
                room_record.room_number;

        ELSIF room_record.available_beds = 1 THEN

            RAISE NOTICE
                'Room %: NEARLY FULL - Only 1 bed available.',
                room_record.room_number;

        ELSE

            RAISE NOTICE
                'Room %: AVAILABLE - % beds available.',
                room_record.room_number,
                room_record.available_beds;

        END IF;

    END LOOP;
END $$;





----------Temporary test for nearly full
UPDATE hostel_rooms
SET available_beds = 1
WHERE room_id = 2;



-------------Temporary test for full
UPDATE hostel_rooms
SET available_beds = 0
WHERE room_id = 2;



---------Restore room 2
UPDATE hostel_rooms
SET available_beds = 3
WHERE room_id = 2;





--------WHILE loop
DO $$
DECLARE
    reminder_number INTEGER := 1;
BEGIN

    WHILE reminder_number <= 3 LOOP

        RAISE NOTICE
            'Hostel Preparation Reminder %: Prepare rooms for student allocation.',
            reminder_number;

        reminder_number := reminder_number + 1;

    END LOOP;

END $$;







----------Numeric FOR loop
DO $$
BEGIN

    FOR check_number IN 1..3 LOOP

        RAISE NOTICE
            'Room Check %: Check room availability and condition.',
            check_number;

    END LOOP;

END $$;








-----------CREATE allocate_room PROCEDURE
CREATE OR REPLACE PROCEDURE allocate_room(
    p_room_id INTEGER,
    p_student_name VARCHAR,
    p_student_number VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_beds INTEGER;
BEGIN

    IF p_student_number IS NULL
       OR TRIM(p_student_number) = '' THEN

        RAISE EXCEPTION
            'Invalid student number. Student number cannot be blank.';

    END IF;


    SELECT available_beds
    INTO current_beds
    FROM hostel_rooms
    WHERE room_id = p_room_id;


    IF NOT FOUND THEN

        RAISE EXCEPTION
            'Room ID % does not exist.',
            p_room_id;

    END IF;


    IF current_beds <= 0 THEN

        RAISE NOTICE
            'Allocation rejected. Room % is full.',
            p_room_id;

        RETURN;

    END IF;


    UPDATE hostel_rooms
    SET available_beds = available_beds - 1
    WHERE room_id = p_room_id;


    INSERT INTO allocations
    (
        room_id,
        student_name,
        student_number,
        status
    )
    VALUES
    (
        p_room_id,
        p_student_name,
        p_student_number,
        'Allocated'
    );


    RAISE NOTICE
        'Room allocation successful for student %.',
        p_student_name;

END;
$$;






-----------First valid allocation
CALL allocate_room(
    1,
    'Titus Bwalya',
    '202402843'
);





-----------Second valid allocation
CALL allocate_room(
    2,
    'John Phiri',
    '202303123'
);





-----------Third valid allocation
CALL allocate_room(
    3,
    'Mary Banda',
    '202424456'
);





------------Check the results
SELECT * FROM hostel_rooms
ORDER BY room_id;



SELECT * FROM allocations
ORDER BY allocation_id;







------------CREATE check_out PROCEDURE
CREATE OR REPLACE PROCEDURE check_out(
    p_allocation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    allocation_room INTEGER;
    allocation_status VARCHAR(20);
BEGIN

    SELECT room_id,
           status
    INTO allocation_room,
         allocation_status
    FROM allocations
    WHERE allocation_id = p_allocation_id;


    IF NOT FOUND THEN

        RAISE EXCEPTION
            'Allocation ID % does not exist.',
            p_allocation_id;

    END IF;


    IF allocation_status = 'Allocated' THEN

        UPDATE hostel_rooms
        SET available_beds = available_beds + 1
        WHERE room_id = allocation_room;


        UPDATE allocations
        SET status = 'Checked Out'
        WHERE allocation_id = p_allocation_id;


        RAISE NOTICE
            'Allocation % checked out successfully. Bed released.',
            p_allocation_id;

    ELSE

        RAISE NOTICE
            'Allocation % is already checked out. No bed released.',
            p_allocation_id;

    END IF;

END;
$$;




-----------First checkout
CALL check_out(1);




---------Second checkout of the same student
CALL check_out(1);




----------------Verify
SELECT * FROM hostel_rooms
ORDER BY room_id;




SELECT * FROM allocations
ORDER BY allocation_id;





-----------EXPLICIT CURSOR
DO $$
DECLARE
    room_cursor CURSOR FOR
        SELECT room_id,
               hostel_name,
               room_number,
               available_beds
        FROM hostel_rooms
        WHERE available_beds <= 1;

    room_record RECORD;
BEGIN

    OPEN room_cursor;


    LOOP

        FETCH room_cursor
        INTO room_record;


        EXIT WHEN NOT FOUND;


        RAISE NOTICE
            'Low availability - Hostel: %, Room: %, Beds remaining: %',
            room_record.hostel_name,
            room_record.room_number,
            room_record.available_beds;

    END LOOP;


    CLOSE room_cursor;

END $$;



---------------Temporary test if no room has 1 bed
UPDATE hostel_rooms
SET available_beds = 1
WHERE room_id = 2;


---------------EXCEPTION FOR BLANK STUDENT NUMBER
DO $$
BEGIN

    BEGIN

        CALL allocate_room(
            3,
            'Peter Mwansa',
            ''
        );


    EXCEPTION
        WHEN OTHERS THEN

            RAISE NOTICE
                'EXCEPTION HANDLED: %',
                SQLERRM;

    END;

END $$;



------------Final hostel rooms
SELECT
    room_id,
    hostel_name,
    room_number,
    capacity,
    available_beds
FROM hostel_rooms
ORDER BY room_id;



----------Final allocations
SELECT
    allocation_id,
    room_id,
    student_name,
    student_number,
    status
FROM allocations
ORDER BY allocation_id;



