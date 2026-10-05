-------------Create tables and insert medicines
CREATE TABLE medicines (
    medicine_id SERIAL PRIMARY KEY,
    medicine_name VARCHAR(100) NOT NULL,
    quantity_in_stock INTEGER NOT NULL,
    reorder_level INTEGER NOT NULL
);


--------checking result
SELECT * FROM medicines;



------------Create the dispensing_records table
CREATE TABLE dispensing_records (
    dispensing_id SERIAL PRIMARY KEY,
    medicine_id INTEGER NOT NULL,
    patient_name VARCHAR(100) NOT NULL,
    quantity_dispensed INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL
);





-----------Add the foreign key
ALTER TABLE dispensing_records
ADD CONSTRAINT fk_medicine
FOREIGN KEY (medicine_id)
REFERENCES medicines(medicine_id);




-------------Insert at least three medicines
INSERT INTO medicines
(medicine_name, quantity_in_stock, reorder_level)
VALUES
('Paracetamol', 100, 20),
('Amoxicillin', 80, 15),
('Ibuprofen', 60, 10);



------------results checking
SELECT * FROM medicines
ORDER BY medicine_id;




SELECT * FROM dispensing_records
ORDER BY dispensing_id;





---------IF / ELSIF / ELSE
DO $$
DECLARE
    medicine_record RECORD;
BEGIN
    FOR medicine_record IN
        SELECT medicine_id,
               medicine_name,
               quantity_in_stock,
               reorder_level
        FROM medicines
        ORDER BY medicine_id
    LOOP

        IF medicine_record.quantity_in_stock <= 0 THEN

            RAISE NOTICE
                'Medicine %: OUT OF STOCK.',
                medicine_record.medicine_name;

        ELSIF medicine_record.quantity_in_stock
              <= medicine_record.reorder_level THEN

            RAISE NOTICE
                'Medicine %: LOW STOCK - % units remaining.',
                medicine_record.medicine_name,
                medicine_record.quantity_in_stock;

        ELSE

            RAISE NOTICE
                'Medicine %: SUFFICIENT STOCK - % units available.',
                medicine_record.medicine_name,
                medicine_record.quantity_in_stock;

        END IF;
    END LOOP;
END $$;




----------Temporary test for low stock

UPDATE medicines
SET quantity_in_stock = 5
WHERE medicine_id = 2;





-----------Restore the original stock
UPDATE medicines
SET quantity_in_stock = 80
WHERE medicine_id = 2;




---------Temporary test for out of stock
UPDATE medicines
SET quantity_in_stock = 0
WHERE medicine_id = 2;


-----------Restore the original stock
UPDATE medicines
SET quantity_in_stock = 80
WHERE medicine_id = 2;





---------WHILE loop
DO $$
DECLARE
    reminder_number INTEGER := 1;
BEGIN
    WHILE reminder_number <= 3 LOOP

        RAISE NOTICE
            'Inventory Reminder %: Check campus clinic medicine stock.',
            reminder_number;

        reminder_number := reminder_number + 1;

    END LOOP;
END $$;





-----------Numeric FOR loop
DO $$
BEGIN
    FOR check_number IN 1..3 LOOP

        RAISE NOTICE
            'Medicine Stock Check %: Verify medicine availability.',
            check_number;

    END LOOP;
END $$;





---------CREATE dispense_medicine PROCEDURE
CREATE OR REPLACE PROCEDURE dispense_medicine(
    p_medicine_id INTEGER,
    p_patient_name VARCHAR,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_stock INTEGER;
BEGIN

    IF p_quantity <= 0 THEN

        RAISE EXCEPTION
            'Invalid dispensing quantity: %. Quantity must be greater than zero.',
            p_quantity;

    END IF;


    SELECT quantity_in_stock
    INTO current_stock
    FROM medicines
    WHERE medicine_id = p_medicine_id;


    IF NOT FOUND THEN

        RAISE EXCEPTION
            'Medicine ID % does not exist.',
            p_medicine_id;

    END IF;


    IF p_quantity > current_stock THEN

        RAISE NOTICE
            'Dispensing rejected. Requested: %, Available: %.',
            p_quantity,
            current_stock;

        RETURN;

    END IF;


    UPDATE medicines
    SET quantity_in_stock = quantity_in_stock - p_quantity
    WHERE medicine_id = p_medicine_id;


    INSERT INTO dispensing_records
    (
        medicine_id,
        patient_name,
        quantity_dispensed,
        status
    )
    VALUES
    (
        p_medicine_id,
        p_patient_name,
        p_quantity,
        'Dispensed'
    );


    RAISE NOTICE
        'Successfully dispensed % unit(s) of medicine to %.',
        p_quantity,
        p_patient_name;

END;
$$;




------------First valid dispensing

CALL dispense_medicine(
    1,
    'Titus Bwalya',
    10
);



------------second valid dispensing

CALL dispense_medicine(
    2,
    'John Phiri',
    15
);



------------third valid dispensing

CALL dispense_medicine(
    3,
    'Mary Banda',
    5
);




---------Test exceeding available stock
CALL dispense_medicine(
    1,
    'Peter Mwansa',
    150
);



----------checking results
SELECT * FROM medicines
ORDER BY medicine_id;







SELECT * FROM dispensing_records
ORDER BY dispensing_id;






----------CREATE reverse_dispensing PROCEDURE
CREATE OR REPLACE PROCEDURE reverse_dispensing(
    p_dispensing_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    selected_medicine INTEGER;
    dispensed_quantity INTEGER;
    dispensing_status VARCHAR(20);
BEGIN

    SELECT medicine_id,
           quantity_dispensed,
           status
    INTO selected_medicine,
         dispensed_quantity,
         dispensing_status
    FROM dispensing_records
    WHERE dispensing_id = p_dispensing_id;


    IF NOT FOUND THEN

        RAISE EXCEPTION
            'Dispensing record ID % does not exist.',
            p_dispensing_id;

    END IF;


    IF dispensing_status = 'Dispensed' THEN

        UPDATE medicines
        SET quantity_in_stock =
            quantity_in_stock + dispensed_quantity
        WHERE medicine_id = selected_medicine;


        UPDATE dispensing_records
        SET status = 'Reversed'
        WHERE dispensing_id = p_dispensing_id;


        RAISE NOTICE
            'Dispensing record % reversed. % unit(s) returned to stock.',
            p_dispensing_id,
            dispensed_quantity;

    ELSE

        RAISE NOTICE
            'Dispensing record % has already been reversed. No stock returned.',
            p_dispensing_id;

    END IF;

END;
$$;







---------Reverse the first dispensing
CALL reverse_dispensing(1);


---------Attempt to reverse it again
CALL reverse_dispensing(1);



-----------checking results
SELECT * FROM medicines
ORDER BY medicine_id;





SELECT * FROM dispensing_records
ORDER BY dispensing_id;



-----------EXPLICIT CURSOR FOR LOW STOCK
DO $$
DECLARE
    medicine_cursor CURSOR FOR
        SELECT medicine_id,
               medicine_name,
               quantity_in_stock,
               reorder_level
        FROM medicines
        WHERE quantity_in_stock <= reorder_level;

    medicine_record RECORD;
BEGIN

    OPEN medicine_cursor;


    LOOP

        FETCH medicine_cursor
        INTO medicine_record;


        EXIT WHEN NOT FOUND;


        RAISE NOTICE
            'LOW STOCK ALERT - Medicine: %, Stock: %, Reorder Level: %',
            medicine_record.medicine_name,
            medicine_record.quantity_in_stock,
            medicine_record.reorder_level;

    END LOOP;


    CLOSE medicine_cursor;

END $$;







-------Temporary cursor test
UPDATE medicines
SET quantity_in_stock = 5
WHERE medicine_id = 3;



-----------Restore the correct stock
UPDATE medicines
SET quantity_in_stock = 55
WHERE medicine_id = 3;


-----------last stock
UPDATE medicines
SET quantity_in_stock = 65
WHERE medicine_id = 2;




-------------EXCEPTION HANDLING FOR NEGATIVE QUANTITY
DO $$
BEGIN

    BEGIN

        CALL dispense_medicine(
            1,
            'Peter Mwansa',
            -5
        );


    EXCEPTION
        WHEN OTHERS THEN

            RAISE NOTICE
                'EXCEPTION HANDLED: %',
                SQLERRM;

    END;

END $$;







INSERT INTO dispensing_records
(
    medicine_id,
    patient_name,
    quantity_dispensed,
    status
)
VALUES
(
    2,
    'John Phiri',
    15,
    'Dispensed'
);



------------Final medicine stock
SELECT
    medicine_id,
    medicine_name,
    quantity_in_stock,
    reorder_level
FROM medicines
ORDER BY medicine_id;




---------Final dispensing records
SELECT
    dispensing_id,
    medicine_id,
    patient_name,
    quantity_dispensed,
    status
FROM dispensing_records
ORDER BY dispensing_id;


