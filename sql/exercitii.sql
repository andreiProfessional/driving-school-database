-- Ex. 6
CREATE OR REPLACE PROCEDURE raport_categorie_permis (
    p_id_categorie_permis IN CATEGORIE_PERMIS.ID_CATEGORIE_PERMIS%TYPE
) IS
    TYPE t_instructori IS TABLE OF INSTRUCTOR.NUME%TYPE INDEX BY PLS_INTEGER;
    v_instructori t_instructori;
    TYPE t_autovehicule IS TABLE OF AUTOVEHICUL.NUMAR_INMATRICULARE%TYPE;
    v_autovehicule t_autovehicule;
    TYPE t_top_cursuri IS VARRAY(3) OF CURS.DENUMIRE%TYPE;
    v_top_cursuri t_top_cursuri := t_top_cursuri();
    v_nr_instructori NUMBER;
BEGIN
    v_nr_instructori := 0;
    FOR i IN (
        SELECT i2.id_instructor, i2.nume
        FROM CATEGORIE_PERMIS_INSTRUCTOR cpi
        JOIN INSTRUCTOR i2 ON i2.ID_INSTRUCTOR = cpi.ID_INSTRUCTOR
        WHERE cpi.ID_CATEGORIE_PERMIS = p_id_categorie_permis
    ) LOOP
        v_nr_instructori := v_nr_instructori + 1;
        v_instructori(v_nr_instructori) := i.nume;
    END LOOP;

    SELECT NUMAR_INMATRICULARE BULK COLLECT INTO v_autovehicule
    FROM AUTOVEHICUL
    WHERE ID_CATEGORIE_PERMIS = p_id_categorie_permis;

    FOR c IN (
        SELECT DENUMIRE
        FROM (
            SELECT DENUMIRE
            FROM CURS
            WHERE ID_CATEGORIE_PERMIS = p_id_categorie_permis
            ORDER BY ORE_PREGATIRE
        )
        WHERE ROWNUM <= 3
    ) LOOP
        v_top_cursuri.EXTEND;
        v_top_cursuri(v_top_cursuri.COUNT) := c.DENUMIRE;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Instructori eligibili:');
    FOR i IN 1 .. v_nr_instructori LOOP
        DBMS_OUTPUT.PUT_LINE(i || ' - ' || v_instructori(i));
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Autovehicule compatibile:');
    FOR j IN 1..v_autovehicule.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(v_autovehicule(j));
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'TOP 3 cele mai scurte cursuri:');
    FOR k IN 1..v_top_cursuri.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(v_top_cursuri(k));
    END LOOP;
END;
/
BEGIN
    raport_categorie_permis(4);
END;
/


-- Ex. 7
CREATE OR REPLACE PROCEDURE raport_instructor_categorii_permis_autovehicule (
    p_id_instructor IN INSTRUCTOR.ID_INSTRUCTOR%TYPE
) IS
    CURSOR c_categorii_permis IS
        SELECT cp.ID_CATEGORIE_PERMIS, cp.COD
        FROM CATEGORIE_PERMIS cp
        JOIN CATEGORIE_PERMIS_INSTRUCTOR cpi ON cp.ID_CATEGORIE_PERMIS = cpi.ID_CATEGORIE_PERMIS
        WHERE cpi.ID_INSTRUCTOR = p_id_instructor;
    CURSOR c_autovehicule (p_id_categorie_permis IN CATEGORIE_PERMIS.ID_CATEGORIE_PERMIS%TYPE) IS
        SELECT a.NUMAR_INMATRICULARE, a.MARCA, a.MODEL
        FROM AUTOVEHICUL a
        WHERE a.ID_CATEGORIE_PERMIS = p_id_categorie_permis;
    v_id_categ CATEGORIE_PERMIS.ID_CATEGORIE_PERMIS%TYPE;
    v_cod_categ CATEGORIE_PERMIS.COD%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Instructorul cu ID-ul ' || p_id_instructor || ' are optiunile urmatoare:');
    OPEN c_categorii_permis;
    LOOP
        FETCH c_categorii_permis INTO v_id_categ, v_cod_categ;
        EXIT WHEN c_categorii_permis%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Categoria ' || v_cod_categ || ' :');
        FOR auto IN c_autovehicule(v_id_categ) LOOP
            DBMS_OUTPUT.PUT_LINE('  Autovehicul: ' || auto.MARCA || ' ' || auto.MODEL || ' (' || auto.NUMAR_INMATRICULARE || ')');
        END LOOP;
    END LOOP;
    CLOSE c_categorii_permis;
END;
/
BEGIN
    FOR i IN 1..5 LOOP
        raport_instructor_categorii_permis_autovehicule(i);
        DBMS_OUTPUT.PUT_LINE('======================================================');
    END LOOP;
END;
/


-- Ex. 8
CREATE OR REPLACE FUNCTION taxa_elev_curs (
    p_cnp_elev IN ELEV.CNP%TYPE,
    p_id_curs  IN CURS.ID_CURS%TYPE)
    RETURN NUMBER IS taxa CONTRACT.TAXA%type;
BEGIN
    SELECT ctr.TAXA INTO taxa
    FROM CONTRACT ctr
    JOIN ELEV e ON e.ID_ELEV = ctr.ID_ELEV
    JOIN CURS crs ON crs.ID_CURS = ctr.ID_CURS
    WHERE e.CNP = p_cnp_elev AND crs.ID_CURS = p_id_curs;
    RETURN taxa;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Elevul nu are contract pentru acest curs.');
        RETURN -1;
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Exista mai multe contracte pentru acest elev la acest curs.');
        RETURN -2;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Eroare neprevazuta: ' || SQLERRM);
        RETURN -3;
END;
/
DECLARE
    v_rezultat CONTRACT.TAXA%type;
BEGIN
    v_rezultat := taxa_elev_curs('1850424123456', 11);
    DBMS_OUTPUT.PUT_LINE('Taxă: ' || v_rezultat || ' Lei');
    DBMS_OUTPUT.PUT('Eroare NO DATA FOUND: ');
    v_rezultat := taxa_elev_curs('1840526123456', 5);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT('Eroare TOO MANY ROWS: ');
    v_rezultat := taxa_elev_curs('1860209123456', 6);
END;
/


-- Ex. 9
CREATE OR REPLACE PROCEDURE instructori_elev_categorie_permis(
    p_cnp_elev IN ELEV.CNP%TYPE,
    p_id_categorie_permis IN CATEGORIE_PERMIS_INSTRUCTOR.ID_CATEGORIE_PERMIS%TYPE
) IS
    TYPE t_instructori IS TABLE OF INSTRUCTOR.NUME%TYPE;
    v_instructori t_instructori;
    CNP_INVALID EXCEPTION;
    CATEGORIE_INVALIDA EXCEPTION;
    INSTRUCTORI_INEXISTENTI EXCEPTION;
BEGIN
    IF p_cnp_elev IS NULL OR LENGTH(p_cnp_elev) != 13 THEN
        RAISE CNP_INVALID;
    END IF;
    IF p_id_categorie_permis IS NULL OR p_id_categorie_permis < 1 THEN
        RAISE CATEGORIE_INVALIDA;
    END IF;
    SELECT DISTINCT i.nume BULK COLLECT INTO v_instructori
    FROM ELEV e
    JOIN CONTRACT ctr ON ctr.ID_ELEV = e.ID_ELEV
    JOIN SEDINTA s ON s.ID_CONTRACT = ctr.ID_CONTRACT
    JOIN INSTRUCTOR i ON i.ID_INSTRUCTOR = s.ID_INSTRUCTOR
    JOIN CATEGORIE_PERMIS_INSTRUCTOR cpi ON cpi.ID_INSTRUCTOR = i.ID_INSTRUCTOR
    WHERE e.CNP = p_cnp_elev AND cpi.ID_CATEGORIE_PERMIS = p_id_categorie_permis;
    IF v_instructori.COUNT = 0 THEN
        RAISE INSTRUCTORI_INEXISTENTI;
    END IF;
    DBMS_OUTPUT.PUT_LINE('Instructorii care au făcut ședințe cu elevul dat și care dețin categoria de permis dată:');
    FOR i IN 1..v_instructori.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('- ' || v_instructori(i));
    END LOOP;
EXCEPTION
    WHEN CNP_INVALID THEN
        DBMS_OUTPUT.PUT_LINE('CNP-ul este invalid.');
    WHEN CATEGORIE_INVALIDA THEN
        DBMS_OUTPUT.PUT_LINE('Categoria de permis este invalidă.');
    WHEN INSTRUCTORI_INEXISTENTI THEN
        DBMS_OUTPUT.PUT_LINE('Niciun instructor cu această categorie de permis nu a făcut ședințe cu acest elev.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Alta eroare: ' || SQLERRM);
END;
/
BEGIN
    instructori_elev_categorie_permis('1860209123456', 4);
    instructori_elev_categorie_permis('184052612345', 3);
    instructori_elev_categorie_permis('1850424123456', 0);
    instructori_elev_categorie_permis('1860209123456', 7);
END;
/



-- Ex. 10
CREATE OR REPLACE TRIGGER trig_lmd_elev
BEFORE INSERT OR UPDATE OR DELETE ON ELEV
BEGIN
    IF MOD(TO_NUMBER(TO_CHAR(SYSDATE, 'MI')), 2) = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nu este permisă modificarea datelor despre elevi în minutele pare ale zilei.');
    END IF;
END;
/
BEGIN
    SELECT TO_CHAR(SYSDATE, 'MI') AS MINUT_CURENT FROM DUAL;
    SELECT * FROM ELEV WHERE ID_ELEV = 100;
    INSERT INTO ELEV (ID_ELEV, CNP, NUME) VALUES (100, '1881029123456', 'Florin Gardoș');
    SELECT * FROM ELEV WHERE ID_ELEV = 100;
    UPDATE ELEV SET NUME = 'Leandro Tatu' WHERE ID_ELEV = 100;
    SELECT * FROM ELEV WHERE ID_ELEV = 100;
    DELETE FROM ELEV WHERE ID_ELEV = 100;
    SELECT * FROM ELEV WHERE ID_ELEV = 100;
END;
/


-- Ex. 11
CREATE OR REPLACE TRIGGER trig_lmd_instructor
BEFORE INSERT OR UPDATE OR DELETE ON INSTRUCTOR
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.DATA_ANGAJARII IS NULL THEN
            :NEW.DATA_ANGAJARII := SYSDATE;
        END IF;
    END IF;
    IF UPDATING THEN
        IF :NEW.SALARIU < :OLD.SALARIU THEN
            RAISE_APPLICATION_ERROR(-20002, 'Nu este permisă scăderea salariului unui instructor.');
        END IF;
    END IF;
    IF DELETING THEN
        IF MOD(TO_NUMBER(TO_CHAR(SYSDATE, 'MI')), 2) = 1 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Ștergerea instructorilor nu este permisă în minutele impare ale zilei.');
        END IF;
    END IF;
END;
/
SELECT * FROM INSTRUCTOR WHERE ID_INSTRUCTOR = 100;
INSERT INTO INSTRUCTOR (ID_INSTRUCTOR, NUME, SALARIU) VALUES(100, 'Xavi Hernandez', 11500);
SELECT * FROM INSTRUCTOR WHERE ID_INSTRUCTOR = 100;

SELECT * FROM INSTRUCTOR WHERE ID_INSTRUCTOR = 200;
INSERT INTO INSTRUCTOR (ID_INSTRUCTOR, NUME, DATA_ANGAJARII, SALARIU)
    VALUES(200, 'Johan Cruyff', DATE '2020-01-01', 12000);
SELECT * FROM INSTRUCTOR WHERE ID_INSTRUCTOR = 200;

UPDATE INSTRUCTOR SET SALARIU = 11000 WHERE ID_INSTRUCTOR = 100;
SELECT * FROM INSTRUCTOR WHERE ID_INSTRUCTOR = 100;
UPDATE INSTRUCTOR SET SALARIU = 12000 WHERE ID_INSTRUCTOR = 100;
SELECT * FROM INSTRUCTOR WHERE ID_INSTRUCTOR = 100;

SELECT TO_CHAR(SYSDATE, 'MI') AS MINUT_CURENT FROM DUAL;
DELETE FROM INSTRUCTOR WHERE ID_INSTRUCTOR = 100;
SELECT * FROM INSTRUCTOR WHERE ID_INSTRUCTOR = 100;
DELETE FROM INSTRUCTOR WHERE ID_INSTRUCTOR = 200;
SELECT * FROM INSTRUCTOR WHERE ID_INSTRUCTOR = 200;
/


-- Ex. 12
CREATE SEQUENCE SECVENTA_INFORMATII START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE TABLE INFORMATII (
    ID_INFORMATII NUMBER PRIMARY KEY,
    DATA DATE
);
CREATE OR REPLACE TRIGGER trig_ldd
BEFORE CREATE OR DROP OR ALTER ON SCHEMA
BEGIN
    INSERT INTO INFORMATII VALUES (SECVENTA_INFORMATII.NEXTVAL, SYSDATE);
END;
/
SELECT * FROM INFORMATII;
CREATE TABLE TEST (id NUMBER);
SELECT * FROM INFORMATII;
ALTER TABLE TEST ADD (nume VARCHAR2(50));
SELECT * FROM INFORMATII;
DROP TABLE TEST;
SELECT * FROM INFORMATII;
/
