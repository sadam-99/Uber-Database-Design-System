-------------------------
--1)- Create User table
-------------------------

CREATE TABLE UberUSER
(
  UberID       varchar(15)     NOT NULL,
  FName        varchar(50)     NOT NULL,
  LName        varchar(50)     NOT NULL,
  PhNo         int        NOT NULL,
  Email        varchar(50)     NOT NULL,
  Address      varchar(50)     NOT NULL,
  DOB          DATE        NOT NULL,

  PRIMARY KEY(UberID)
); 

--------------------------
--2)- Create Customer table
--------------------------
CREATE TABLE Customer
(
  CID               varchar(15) NOT NULL,
  CustomerType      varchar(15) NOT NULL ,

  PRIMARY KEY(CID),
  FOREIGN KEY (CID) REFERENCES UberUser(UberID) ON DELETE CASCADE
);

DROP TABLE driver;

--3)- Create Driver table
----------------------
----------------------
CREATE TABLE Driver
(
  DID     varchar(15)      NOT NULL,
  SSN          int          NOT NULL,
  DLNo         varchar(50)      NOT NULL,
  DLExpiry     DATE        NOT NULL,

  PRIMARY KEY(DID),
  FOREIGN KEY (DID) REFERENCES UberUser(UberID) ON DELETE CASCADE
);

-----------------------
--4)- Create Vehicle table
-----------------------
CREATE TABLE Vehicle 
(
  VID             varchar(15)    NOT NULL,
  DrID             varchar(50)    NOT NULL,
  ModelN          varchar(50)    NOT NULL,
  Color           varchar(20)    NOT NULL,
  ManufYear       int           NOT NULL,
  PurDate         DATE          NOT NULL,
  Active          varchar(18)        NOT NULL,
  Condition       varchar(15)    NOT NULL, 
  Cpty              int        NOT NULL,
  InsuranceNo     varchar(15)    NOT NULL,
  InsuranceExpiry varchar(15)    NOT NULL,
  LastChecked     DATE        NOT NULL,

  PRIMARY KEY(VID),
  FOREIGN KEY (DrID) REFERENCES Driver(DID) ON DELETE CASCADE
);

-----------------------
--5)- Create TripRequests table
-----------------------
CREATE TABLE TripRequests  
(
  TripID       varchar(15)    NOT NULL,
  CID          varchar(50)    NOT NULL,
  DID          varchar(50)    NOT NULL,
  TripType     varchar(50)    NOT NULL,
  PickupLoc    varchar(50)    NOT NULL,
  DropoffLoc   varchar(50)    NOT NULL,
  Distance      float      NOT NULL,
  EstFare      float      NOT NULL,
  TID          varchar(15)    NOT NULL,

  PRIMARY KEY(TripID),
  FOREIGN KEY (TID) REFERENCES PaymentMethod(TID) ON DELETE CASCADE,
  FOREIGN KEY (CID) REFERENCES Customer(CID) ON DELETE CASCADE,
  FOREIGN KEY (DID) REFERENCES Driver(DID)  ON DELETE CASCADE
);
-------------------------
--6)- Create CompletedTrips table
-------------------------

CREATE TABLE CompletedTrips  
(
  TripID            varchar(15)    NOT NULL,
  DriverArrivedAt   TIMESTAMP          NOT NULL,
  PickupTime        TIMESTAMP          NOT NULL,
  DropoffTime       TIMESTAMP          NOT NULL,
  duration          int            NOT NULL,
  ActFare           float      NOT NULL,
  Tip               float      NOT NULL,
  Surge        float     NULL,

  PRIMARY KEY(TripID),
  FOREIGN KEY (TripID) REFERENCES TripRequests(TripID) ON DELETE CASCADE
);
-------------------------
--7)- Create IncompleteTrips table
-------------------------

CREATE TABLE IncompleteTrips  
(
  TripID            varchar(15)    NOT NULL,
  BookingTime       TIMESTAMP                   NOT NULL, 
  CancelTime        TIMESTAMP          NOT NULL, 
  Reason            varchar(30)            NOT NULL,

PRIMARY KEY(TripID),
FOREIGN KEY (TripID) REFERENCES TripRequests(TripID) ON DELETE CASCADE
);


-----------------------
--8)- Create PaymentMethod table
-----------------------
CREATE TABLE PaymentMethod
(
  TID          varchar(50)     NOT NULL, 
  CardNo       int        NOT NULL,
  CVV          int        NOT NULL,    
  ExpiryDate	 DATE           NOT NULL, 
  AccType      varchar(50)    NOT NULL,
  CardType     varchar(50)    NOT NULL,
  BillingAdd   varchar(50)    NOT NULL,

  PRIMARY KEY(TID)
);


-----------------------
--9)- Create PersonalPayment table
-----------------------
CREATE TABLE PersonalPayment  
(
  TID           varchar(15)    NOT NULL,
  NameOnCard    varchar(50)    NOT NULL,

  PRIMARY KEY(TID),
  FOREIGN KEY (TID) REFERENCES PaymentMethod(TID) ON DELETE CASCADE
);

-------------------------
--10)- Create BusinessPayment table
-------------------------
CREATE TABLE BusinessPayment  
(
  TID           varchar(15)    NOT NULL,
  CompanyName   varchar(50)    NOT NULL,

  PRIMARY KEY(TID),
  FOREIGN KEY (TID) REFERENCES PaymentMethod(TID) ON DELETE CASCADE
);

-------------------------
--11)- Create Rating table
-------------------------

CREATE TABLE Rating  
(
  TripID               varchar(15)    NOT NULL,
  DriverRating      int        NOT NULL,
  CustomerRating    int        NOT NULL,  
  DriverFeedback    varchar(15)    NOT NULL,
  CustomerFeedback  varchar(15)    NOT NULL,

  PRIMARY KEY(TripID),
  FOREIGN KEY (TripID) REFERENCES CompletedTrips(TripID) ON DELETE CASCADE
);

-------------------------
--12)- Create Shift table
-------------------------


CREATE TABLE Shift  
(
  DID           varchar(15)    NOT NULL,
  DT          DATE           NOT NULL,
  LoginTime     TIMESTAMP                   NOT NULL, 
  LogoutTime    TIMESTAMP          NOT NULL, 

  PRIMARY KEY(DID, DT),
  FOREIGN KEY (DID) REFERENCES Driver(DID) ON DELETE CASCADE
);

-------------------------
--13)- Create Offers table
-------------------------

CREATE TABLE Offers
(
  CID            varchar(15)    NOT NULL,
  PromoCode      varchar(15)    NOT NULL,
  PromoDiscount  float      NOT NULL,

  PRIMARY KEY(CID),
  FOREIGN KEY (CID) REFERENCES Customer(CID) ON DELETE CASCADE
);


-- Stored Procedures---

/* Procedure that will calculate the average rating of the driver */
create or replace PROCEDURE Average_Rating AS
CURSOR DrivRating IS SELECT AVG(R.DriverRating) as AvgRating, T.DID FROM TripRequests T, Rating R WHERE T.TripID=R.TripID GROUP BY T.DID;
thisRating DrivRating%ROWTYPE;
BEGIN
OPEN DrivRating;
LOOP
  FETCH DrivRating INTO thisRating;
  EXIT WHEN (DrivRating%NOTFOUND);
  dbms_output.put_line(thisRating.AvgRating || ' is the Average rating for the driver ID:' || thisRating.DID);
END LOOP;
CLOSE DrivRating;
END;

begin 
Average_Rating;
end;


SET SERVEROUTPUT ON
/* Procedure that will calculate the Total fare for the ride */

create or replace PROCEDURE Calculate_Fare(Base_fare IN number, Service_Tax IN number, Cost_per_mile IN number, Cost_per_min IN number) AS
CURSOR Trip_total_fare IS
SELECT
    "A1". "TRIPID"    "TRIPID",
    "A1"."DURATION"   "DURATION",
    "A2"."DISTANCE"   "DISTANCE",
    "A1"."SURGE"      "SURGE"
FROM
    "SXG190040"."TRIPREQUESTS"     "A2",
    "SXG190040"."COMPLETEDTRIPS"   "A1"
WHERE
    "A2"."TRIPID" = "A1"."TRIPID";
thisTrip Trip_total_fare%rowtype;
thisTotalFare TripRequests.EstFare%TYPE;
BEGIN
OPEN Trip_total_fare;
LOOP
  FETCH Trip_total_fare INTO thisTrip;
  EXIT WHEN (Trip_total_fare%NOTFOUND);
  --thisTrip.duration:= thisTrip.DropoffTime  - thisTrip.PickupTime
  thisTotalFare:= (Base_fare + Service_Tax + Cost_per_mile*thisTrip.distance + Cost_per_min*thisTrip.duration )*(1 + thisTrip.Surge);
  dbms_output.put_line(thisTotalFare || ' is the total fare for the Trip ID:' || thisTrip.TripID);
END LOOP;
CLOSE Trip_total_fare;
END;

begin
Calculate_Fare(5,10,1,1);
end;

--- Triggers  ---
/* Trigger for DL Expiry */
create or replace TRIGGER DL_Renewal

create or replace trigger renew
before insert or update
on Driver for each row
when (new.DLEXPIRY < '2019-12-02 15:26:22')
begin
dbms_output.put_line(' HEY!! go renew!!') ;
end;

insert into Uberuser
INSERT INTO DRIVER (DID, SSN, DLNO, DLEXPIRY) VALUES ('U233', '123456789', '12345678', TO_DATE('2018-12-16 15:26:22', 'YYYY-MM-DD HH24:MI:SS'));
select * from Driver where dlexpiry<sysdate;

select to_date_or_null('2000-01-01', 'YYYY-MM-DD') from dual ;


select to_date_or_null('2000-01-01') from dual;

update DRIVER set DLExpiry= '20-MAY-18' where DID= 'U012';
insert into DRIVER values("U000", 1303268333, "58286320", "20-MAY-18");
insert into DRIVER values("U000", 1303268333, "58286320", 20-MAY-18);
insert into DRIVER values("U000", 1303268333, "58286320", "20-MAY-18");
/* Trigger for Insurance Expiry */

create or replace TRIGGER Insurance_Renewal
before insert
on Vehicle for each row
when (new.insuranceexpiry < sysdate)
begin
dbms_output.put_line(' HEY!! go renew!!') ;
end;

dbms_output.put_line(SYSDATE);

insert into vehicle values ('V550',	'U012',	'Camry','Black',20-08-10,03-APR-09,	'true','Good',4,'I34567890'	,'04/03/2021','23-OCT-18');
insert into vehicle values ("V551",	"U012",	"Camry","Black",20-08-10,03-APR-09,	"true","Good",4,"I34567890"	,"04/03/18","23-OCT-18");
