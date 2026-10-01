USE mccollins_shipping;
SET time_zone='+00:00';

-- Non-destructive pilot hardening: enforce relationships already used by the application.
DELIMITER $$
DROP PROCEDURE IF EXISTS pilot_fk$$
CREATE PROCEDURE pilot_fk(
  IN t VARCHAR(64), IN n VARCHAR(64), IN c VARCHAR(64),
  IN rt VARCHAR(64), IN rc VARCHAR(64)
)
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME=t AND CONSTRAINT_NAME=n
  ) THEN
    SET @q=CONCAT(
      'ALTER TABLE `',t,'` ADD CONSTRAINT `',n,'` FOREIGN KEY (`',
      c,'`) REFERENCES `',rt,'` (`',rc,'`)'
    );
    PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
  END IF;
END$$
DELIMITER ;

CALL pilot_fk('trips','fk_trips_assignment','assignment_id','assignments','assignment_id');
CALL pilot_fk('trips','fk_trips_driver','driver_id','drivers','driver_id');
CALL pilot_fk('trips','fk_trips_truck','truck_id','trucks','truck_id');
CALL pilot_fk('shipments','fk_shipments_customer_company','customer_company_id','companies','company_id');
CALL pilot_fk('payments','fk_payments_payer_company','payer_company_id','companies','company_id');
CALL pilot_fk('settlements','fk_settlements_carrier_company','carrier_company_id','companies','company_id');
CALL pilot_fk('settlements','fk_settlements_carrier_user','carrier_user_id','users','user_id');
CALL pilot_fk('access_logs','fk_access_logs_user','user_id','users','user_id');

DROP PROCEDURE pilot_fk;
SELECT 'Pilot integrity constraints completed' result;