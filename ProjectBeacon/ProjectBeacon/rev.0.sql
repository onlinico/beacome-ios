--
-- File generated with SQLiteStudio v3.0.7 on Tue Dec 22 10:31:42 2015
--
-- Text encoding used: UTF-8
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table: Emails
CREATE TABLE Emails (
    id        INTEGER PRIMARY KEY AUTOINCREMENT
                      UNIQUE
                      NOT NULL,
    emailType INTEGER,
    email     TEXT,
    cardId    TEXT    REFERENCES Cards (cardId) ON DELETE RESTRICT
                                                ON UPDATE SET DEFAULT
);


-- Table: Users
CREATE TABLE Users (
    userId           INTEGER NOT NULL
                             UNIQUE
                             PRIMARY KEY,
    fullName         TEXT,
    userPicture      BLOB,
    email            TEXT,
    facebookIsLinked BOOLEAN,
    twitterIsLinked  BOOLEAN,
    gPlusIsLinked    BOOLEAN
);


-- Table: Cards
CREATE TABLE Cards (
    cardId    TEXT    NOT NULL
                      PRIMARY KEY
                      UNIQUE,
    logo      BLOB,
    title     TEXT,
    summary   TEXT,
    version   INTEGER NOT NULL,
    shortInfo BOOLEAN NOT NULL
);


-- Table: CardsShare
CREATE TABLE CardsShare (
    id         INTEGER PRIMARY KEY,
    shareGuid  TEXT    NOT NULL,
    cardId     TEXT    REFERENCES Cards (cardId) ON DELETE CASCADE
                                                 ON UPDATE CASCADE
                       NOT NULL,
    permission BOOLEAN NOT NULL,
    email      TEXT    NOT NULL,
    userId     INTEGER,
    version    INTEGER
);


-- Table: URLs
CREATE TABLE URLs (
    id      INTEGER PRIMARY KEY AUTOINCREMENT
                    NOT NULL
                    UNIQUE,
    urlType INTEGER,
    url     TEXT,
    cardId  TEXT    REFERENCES Cards (cardId) ON DELETE CASCADE
                                              ON UPDATE CASCADE
);


-- Table: Beacons
CREATE TABLE Beacons (
    beaconUid TEXT    NOT NULL
                      PRIMARY KEY
                      UNIQUE,
    major     INTEGER,
    minor     INTEGER,
    power     INTEGER,
    version   INTEGER
);


-- Table: Permissions
CREATE TABLE Permissions (
    id         INTEGER NOT NULL
                       PRIMARY KEY AUTOINCREMENT
                       UNIQUE,
    userId     INTEGER NOT NULL
                       REFERENCES Users (userId) ON DELETE CASCADE
                                                 ON UPDATE CASCADE,
    cardId     TEXT    NOT NULL
                       REFERENCES Cards (cardId) ON DELETE CASCADE
                                                 ON UPDATE CASCADE,
    permission INTEGER NOT NULL
);


-- Table: CardsHistory
CREATE TABLE CardsHistory (
    id                 INTEGER  PRIMARY KEY AUTOINCREMENT,
    cardId             TEXT     REFERENCES Cards (cardId) ON DELETE CASCADE
                                                          ON UPDATE CASCADE,
    userId             INTEGER  REFERENCES Users (userId) ON DELETE CASCADE
                                                          ON UPDATE CASCADE,
    visitDateTimeStamp DATETIME,
    isFavourite        BOOLEAN,
    latitude           DOUBLE,
    longitude          DOUBLE,
    distance           DOUBLE
);


-- Table: Phones
CREATE TABLE Phones (
    id          INTEGER NOT NULL
                        UNIQUE
                        PRIMARY KEY AUTOINCREMENT,
    phoneType   INTEGER,
    phoneNumber TEXT,
    cardId      TEXT    REFERENCES Cards (cardId) ON DELETE CASCADE
                                                  ON UPDATE SET DEFAULT
);


-- Table: BeaconsCards
CREATE TABLE BeaconsCards (
    id       INTEGER PRIMARY KEY AUTOINCREMENT
                     NOT NULL
                     UNIQUE,
    beaconId TEXT    REFERENCES Beacons (beaconUid) ON DELETE CASCADE
                                                    ON UPDATE CASCADE
                     NOT NULL,
    cardId   TEXT    REFERENCES Cards (cardId) ON DELETE CASCADE
                                               ON UPDATE CASCADE
                     NOT NULL,
    state    BOOLEAN
);


-- Table: VCards
CREATE TABLE VCards (
    id          INTEGER PRIMARY KEY
                        UNIQUE
                        NOT NULL,
    cardId      TEXT    REFERENCES Cards (cardId) ON DELETE CASCADE
                                                  ON UPDATE CASCADE,
    personImage BLOB,
    fullName    TEXT,
    email       TEXT,
    phone       TEXT,
    vCardData   TEXT,
    version     INTEGER NOT NULL
);


-- Index: permissionUserIndex
CREATE INDEX permissionUserIndex ON Permissions (
    userId
);


-- Index: cardsHistoryUserIndex
CREATE INDEX cardsHistoryUserIndex ON CardsHistory (
    userId
);


-- Index: beaconsCardsCardIndex
CREATE INDEX beaconsCardsCardIndex ON BeaconsCards (
    cardId
);


-- Index: cardsHistoryCardIndex
CREATE INDEX cardsHistoryCardIndex ON CardsHistory (
    cardId
);


-- Index: beaconsCardsBeaconIndex
CREATE INDEX beaconsCardsBeaconIndex ON BeaconsCards (
    beaconId
);


-- Index: vcardIndex
CREATE INDEX vcardIndex ON VCards (
    cardId
);


-- Index: urlIndex
CREATE INDEX urlIndex ON URLs (
    cardId
);


-- Index: emailIndex
CREATE INDEX emailIndex ON Emails (
    cardId
);


-- Index: phoneIndex
CREATE INDEX phoneIndex ON Phones (
    cardId
);


-- Index: permissionCardIndex
CREATE INDEX permissionCardIndex ON Permissions (
    cardId
);

INSERT OR REPLACE INTO Users(userId, fullName, userPicture, email, facebookIsLinked, twitterIsLinked, gPlusIsLinked) VALUES('-1','','','','','','');


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
