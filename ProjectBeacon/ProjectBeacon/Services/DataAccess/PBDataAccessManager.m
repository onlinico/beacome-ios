//
// Created by Oleksandr Malyarenko on 11/16/15.
// Copyright (c) 2015 Onlinico. All rights reserved.
//

#import <objc/runtime.h>
#import "PBDataAccessManager.h"
#import "PBCardsShare.h"
#import "FMDatabase+InOperator.h"
#import "PBBeaconCard.h"
#import "Constants.h"


static NSString *const kDatabasePath = @"project_beacon";

typedef void (^PBDatabaseUpdateBlock)(FMDatabase *db);

typedef void (^PBDatabaseTransactionsUpdateBlock)(FMDatabase *db, BOOL *rollback);

typedef FMResultSet *(^PBDatabaseFetchBlock)(FMDatabase *db);

typedef void (^PBDatabaseFetchResultsBlock)(NSArray *results);


@interface PBDataAccessManager () {
    FMDatabaseQueue *_databaseQueue;
}


@property (nonatomic, strong) FMDatabase *database;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, strong) NSString *databasePath;

@end


@implementation PBDataAccessManager {

}


- (id)init {
    if (self = [super init]) {
        [self setDatabasePath:kDatabasePath];
    }
    return self;
}


- (void)dealloc {
    // Should never be called, but just here for clarity really.
}


#pragma mark - Database init


- (void)setDatabasePath:(NSString *)path {
    _databasePath = [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:path];
    self.database = [[FMDatabase alloc] initWithPath:self.databasePath];
    [self.database open];

    [self checkUpdatesForDatabase];
}


#pragma mark - Application's Documents directory


// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


- (void)checkUpdatesForDatabase {
    int databaseVersion = [self.database intForQuery:@"pragma user_version"];
    int currentDatabaseVersion = [self getCurrentDatabaseVersion];

    if (databaseVersion < currentDatabaseVersion) {
        for (; databaseVersion < currentDatabaseVersion; databaseVersion++) {
            NSString *fileName = [NSString stringWithFormat:@"rev.%i.sql", databaseVersion];
            NSString *sql = [NSString stringWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:fileName] usedEncoding:nil error:nil];
            NSArray *queries = [sql componentsSeparatedByString:@";"];
            for (NSString *query in queries) {
                [self.database executeUpdate:query];
                if ([self.database hadError]) {
                    DDLogError(@"%@", [self.database lastErrorMessage]);
                }
            }
        }
    }

    [self.database executeUpdate:[NSString stringWithFormat:@"pragma user_version = %i", currentDatabaseVersion]];
    [self.database executeUpdate:@"pragma foreign_keys = ON"];
}


- (int)getCurrentDatabaseVersion {
    int databaseVersion = 0;
    NSArray *contentsOfFolder = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[NSBundle mainBundle] bundlePath] error:nil];

    for (NSString *fileName in contentsOfFolder) {
        if ([fileName hasSuffix:@".sql"]) {
            databaseVersion++;
        }
    }
    return databaseVersion;

}


#pragma mark - Properties accessors


- (FMDatabaseQueue *)databaseQueue {
    if (!_databaseQueue) {
        self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
        [_databaseQueue inDatabase:^(FMDatabase *db) {
            BOOL success = [db executeUpdate:@"PRAGMA foreign_keys=ON;"];
            if (!success) {
                DDLogError(@"Foreign keys pragma failed: %@", [db lastErrorMessage]);
            }
        }];
    }
    return _databaseQueue;
}


#pragma mark - Data access methods


- (void)cleanAnonymusData {
    [self runDatabaseBlock:^(FMDatabase *db){
        [db executeUpdate:@"delete from CardsHistory where userId=?", @(kPBDefaultUserId)];
    }];
}


- (void)getDefaultUserWithCallback:(void (^)(PBUser *user))callback {
    [self runFetchForClass:[PBUser class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select * from Users where userId=?", @(kPBDefaultUserId)];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback(results.lastObject);
        }
    }];
}


- (void)getUserById:(NSInteger)id callback:(void (^)(PBUser *user))callback {
    [self runFetchForClass:[PBUser class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select * from Users where userId=?", @(id)];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback(results && results.count > 0 ? results.firstObject : nil);
        }
    }];
}


- (void)addUser:(PBUser *)user {
    [self runDatabaseBlock:^(FMDatabase *db) {
        [db executeUpdate:@"insert or replace into Users(userId, fullName, email, userPicture, facebookIsLinked, twitterIsLinked, gPlusIsLinked) values(?,?,?,?,?,?,?)", @(user.userId), user.fullName, user.email, user.userPicture, @(user.facebookIsLinked), @(user.twitterIsLinked), @(user.gPlusIsLinked)];
    }];
}


- (void)updateUser:(PBUser *)user {
    [self runDatabaseBlock:^(FMDatabase *db) {
        [db executeUpdate:@"update Users set fullName=?, email=?, userPicture=?, facebookIsLinked=?, twitterIsLinked=?, gPlusIsLinked=? where userId=?", user.fullName, user.email, user.userPicture, @(user.facebookIsLinked), @(user.twitterIsLinked), @(user.gPlusIsLinked), @(user.userId)];
    }];
}


- (void)copyAnonymusUserHistoryToUser:(NSInteger)userId {
    [self runDatabaseBlock:^(FMDatabase *db){
        [db executeUpdate:@"update CardsHistory set userId=? where userId=?", @(userId), @(kPBDefaultUserId)];
    }];

}


- (void)getAllUserCards:(NSInteger)userId callback:(void (^)(NSArray *cards))callback {
    [self runFetchForClass:[PBCard class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select p.cardId, p.permission, c.title, c.summary, c.logo, c.version from Permissions as p join Cards as c on p.cardId=c.cardId where p.userId=?", @(userId)];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback(results);
        }
    }];
}


- (void)getAllInfoCards:(NSInteger)userId callback:(void (^)(NSArray *cards))callback {
    [self runFetchForClass:[PBCard class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select h.cardId, h.visitDateTimeStamp, h.isFavourite, h.latitude, h.longitude, h.distance, c.title, c.summary, c.logo, c.version from CardsHistory as h join Cards as c on h.cardId=c.cardId where h.userId=?", @(userId)];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback(results);
        }
    }];
}


- (void)getCardByUid:(NSString *)cardId callback:(void (^)(PBCard *card))callback {
    [self runFetchForClass:[PBCard class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select title, summary, logo, version from Cards where cardId=?", cardId];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback(results.firstObject);
        }
    }];
}


- (void)getDetailsForCard:(PBCard *)card isUserCard:(BOOL)isUserCard callback:(void (^)(PBCard *detailCard))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_enter(group);
        [self getCardByUid:card.cardId callback:^(PBCard *cardInDb) {
            card.title = cardInDb.title;
            card.summary = cardInDb.summary;
            card.logo = cardInDb.logo;
            card.version = cardInDb.version;
            dispatch_group_leave(group);
        }];
        dispatch_group_enter(group);
        [self getPhonesForCardId:card.cardId callback:^(NSArray *phones) {
            card.phones = phones;
            dispatch_group_leave(group);
        }];

        dispatch_group_enter(group);
        [self getEmailsForCardId:card.cardId callback:^(NSArray *emails) {
            card.emails = emails;
            dispatch_group_leave(group);
        }];

        dispatch_group_enter(group);
        [self getUrlsForCardId:card.cardId callback:^(NSArray *urls) {
            card.urls = urls;
            dispatch_group_leave(group);
        }];

        dispatch_group_enter(group);
        [self getVCardsForCardGuid:card.cardId callback:^(NSArray *vCards) {
            card.vCards = vCards;
            dispatch_group_leave(group);
        }];

        if (isUserCard) {
            dispatch_group_enter(group);
            [self getSharesForCardId:card.cardId callback:^(NSArray *shares) {
                card.cardShare = shares;
                dispatch_group_leave(group);
            }];

            dispatch_group_enter(group);
            [self getBeaconsForCard:card callback:^(NSArray *beacons) {
                card.beacons = beacons;
                card.beaconsCount = beacons.count;
                dispatch_group_leave(group);
            }];
        }

        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(card);
            }
        });
    });
}


- (void)getPhonesForCardId:(NSString *)cardId callback:(void (^)(NSArray *phones))callback {
    [self runFetchForClass:[PBCardPhone class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select * from Phones where cardId=?", cardId];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback(results);
        }
    }];
}


- (void)getEmailsForCardId:(NSString *)cardId callback:(void (^)(NSArray *emails))callback {
    [self runFetchForClass:[PBCardEmail class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select * from Emails where cardId=?", cardId];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback(results);
        }
    }];
}


- (void)getUrlsForCardId:(NSString *)cardId callback:(void (^)(NSArray *urls))callback {
    [self runFetchForClass:[PBCardURL class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select * from URLs where cardId=?", cardId];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback(results);
        }
    }];
}


- (void)getSharesForCardId:(NSString *)cardId callback:(void (^)(NSArray *shares))callback {
    [self runFetchForClass:[PBCardsShare class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select cs.id, cs.shareGuid, cs.cardId, cs.userId, cs.email, cs.permission, cs.version, case when u.fullName='' then null else u.fullName end as name , case when u.userPicture='' then null else u.userPicture end as photo from CardsShare as cs join Users as u on cs.userId=u.userId where cardId=?", cardId];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback(results);
        }
    }];
}


- (void)addShares:(NSArray *)shares toCardId:(NSString *)cardId {

    NSMutableArray *sharesToUser = [NSMutableArray array];
    NSMutableArray *sharesToEmail = [NSMutableArray array];
    for (PBCardsShare *cardShare in shares) {
        cardShare.cardId = cardId;
        if (cardShare.userId == -1 && cardShare.shareGuid != nil) {
            [sharesToEmail addObject:cardShare];
        }
        else {
            [sharesToUser addObject:cardShare];
        }
    }
    [self runDatabaseBlockInTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (PBCardsShare *share in sharesToUser) {
            PBUser *user = [self databaseObjectsWithResultSet:[db executeQuery:@"select * from Users where userId=?", @(share.userId)] class:[PBUser class]].firstObject;
            if (!user) {
                PBUser *newUser = [[PBUser alloc] init];
                newUser.userId = share.userId;
                newUser.email = share.email;
                [db executeUpdate:@"insert or replace into Users(userId, fullName, email, facebookIsLinked, twitterIsLinked, gPlusIsLinked) values(?,?,?,?,?,?)", @(newUser.userId), newUser.fullName, newUser.email, @(newUser.facebookIsLinked), @(newUser.twitterIsLinked), @(newUser.gPlusIsLinked)];
            }
            NSInteger count = [db intForQuery:@"select count(id) from CardsShare where userId=? and cardId=?", @(share.userId), cardId];
            if(count > 0){
                [db executeUpdate:@"update CardsShare set permission=?, email=?, version=? where userId=? and cardId=?", @(share.permission), share.email, @(share.version), @(share.userId), cardId];
            }
            else{
                [db executeUpdate:@"insert or replace into CardsShare(shareGuid, cardId, userId, permission, email, version) values (?,?,?,?,?,?)", share.shareGuid, share.cardId, @(share.userId), @(share.permission), share.email, @(share.version)];
            }
        }
        for (PBCardsShare *share in sharesToEmail) {
            NSInteger count = [db intForQuery:@"select count(id) from CardsShare where shareGuid=? and cardId=?", share.shareGuid, cardId];
            if (count > 0) {
                [db executeUpdate:@"update CardsShare set userId=?, permission=?, email=?, version=? where shareGuid=? and cardId=?", @(share.userId), @(share.permission), share.email, @(share.version), share.shareGuid, share.cardId];
            }
            else {
                [db executeUpdate:@"insert or replace into CardsShare(shareGuid, cardId, userId, permission, email, version) values (?,?,?,?,?,?)", share.shareGuid, share.cardId, @(share.userId), @(share.permission), share.email, @(share.version)];
            }
        }
    }];
}


- (void)updateShares:(NSArray *)shares forCardId:(NSString *)cardId {
    NSMutableArray *sharesToUser = [NSMutableArray array];
    NSMutableArray *sharesToEmail = [NSMutableArray array];
    NSMutableArray *existedGuids = [NSMutableArray array];
    NSMutableArray *existedIds = [NSMutableArray array];
    for (PBCardsShare *cardShare in shares) {
        cardShare.cardId = cardId;
        if (cardShare.userId == 0 && cardShare.shareGuid != nil) {
            [sharesToEmail addObject:cardShare];
            [existedGuids addObject:cardShare.shareGuid];
        }
        else {
            [sharesToUser addObject:cardShare];
            [existedIds addObject:@(cardShare.userId)];
        }
    }
    [self runDatabaseBlockInTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (PBCardsShare *share in sharesToUser) {
            PBUser *user = [self databaseObjectsWithResultSet:[db executeQuery:@"select * from Users where userId=?", @(share.userId)] class:[PBUser class]].firstObject;
            if (!user) {
                PBUser *newUser = [[PBUser alloc] init];
                newUser.userId = share.userId;
                newUser.email = share.email;
                [db executeUpdate:@"insert or replace into Users(userId, fullName, email, facebookIsLinked, twitterIsLinked, gPlusIsLinked) values(?,?,?,?,?,?)", @(newUser.userId), newUser.fullName, newUser.email, @(newUser.facebookIsLinked), @(newUser.twitterIsLinked), @(newUser.gPlusIsLinked)];
            }
            NSInteger count = [db intForQuery:@"select count(id) from CardsShare where userId=? and cardId=?", @(share.userId), cardId];
            if(count > 0){
                [db executeUpdate:@"update CardsShare set permission=?, email=?, version=? where userId=? and cardId=?", @(share.permission), share.email, @(share.version), @(share.userId), cardId];
            }
            else{
                [db executeUpdate:@"insert or replace into CardsShare(shareGuid, cardId, userId, permission, email, version) values (?,?,?,?,?,?)", share.shareGuid, share.cardId, @(share.userId), @(share.permission), share.email, @(share.version)];
            }
        }
        for (PBCardsShare *share in sharesToEmail) {
            NSInteger count = [db intForQuery:@"select count(id) from CardsShare where shareGuid=? and cardId=?", share.shareGuid, cardId];
            if (count > 0) {
                [db executeUpdate:@"update CardsShare set userId=?, permission=?, email=?, version=? where shareGuid=? and cardId=?", @(share.userId), @(share.permission), share.email, @(share.version), share.shareGuid, share.cardId];
            }
            else {
                [db executeUpdate:@"insert or replace into CardsShare(shareGuid, cardId, userId, permission, email, version) values (?,?,?,?,?,?)", share.shareGuid, share.cardId, @(share.userId), @(share.permission), share.email, @(share.version)];
            }

        }
        if (existedGuids.count > 0) {
            [db executeUpdateWithInOperator:@"delete from CardsShare where cardId=? and userId=? and shareGuid not in ([?])", cardId, @(kPBDefaultUserId), existedGuids];
        }
        if (existedIds.count > 0) {
            [db executeUpdateWithInOperator:@"delete from CardsShare where cardId=? and shareGuid=? and userId not in ([?])", cardId, kDefaultShareGuid, existedIds];
        }
        if (shares.count == 0) {
            [db executeUpdate:@"delete from CardsShare where cardId=?", cardId];
        }
    }];
}


- (void)deleteShares:(NSArray *)shares forCardId:(NSString *)cardId {
    [self runDatabaseBlockInTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (PBCardsShare *share in shares) {
            [db executeUpdate:@"delete from CardsShare where shareGuid=? or userId=? and cardId=?", share.shareGuid, @(share.userId), share.cardId];
        }
    }];
}


- (void)getInfoCards:(NSInteger)userId fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate callback:(void (^)(NSArray *cards))callback {
    [self runFetchForClass:[PBCard class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select h.cardId, h.visitDateTimeStamp, h.isFavourite, c.title, c.summary, c.logo, c.version from CardsHistory as h join Cards as c on h.cardId=c.cardId where h.userId=? and h.visitDateTimeStamp between ? and ?", @(userId), @([fromDate timeIntervalSince1970]), @([toDate timeIntervalSince1970])];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback(results);
        }
    }];
}


- (void)cardExist:(PBCard *)card callback:(void (^)(BOOL exist, PBCard *existedCard))callback {
    [self runFetchForClass:[PBCard class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select * from Cards where cardId=?", card.cardId];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback((results != nil && results.count > 0), results.firstObject);
        }
    }];
}


- (void)addCard:(PBCard *)card {
    [self runDatabaseBlockInTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"insert or replace into Cards(cardId, logo, title, summary, version, shortInfo) values(?,?,?,?,?,?)", card.cardId, card.logo, card.title, card.summary, @(card.version), @(card.shortInfo)];
        for (PBCardPhone *phone in card.phones) {
            [db executeUpdate:@"insert or replace into Phones(id, phoneType, phoneNumber, cardId) values(?,?,?,?)", @(phone.id), @(phone.phoneType), phone.phoneNumber, card.cardId];
        }
        for (PBCardEmail *email in card.emails) {
            [db executeUpdate:@"insert or replace into Emails(id, emailType, email, cardId) values(?,?,?,?)", @(email.id), @(email.emailType), email.email, card.cardId];
        }
        for (PBCardURL *url in card.urls) {
            [db executeUpdate:@"insert or replace into URLs(id, urlType, url, cardId) values(?,?,?,?)", @(url.id), @(url.urlType), url.url, card.cardId];
        }
        for (PBVCard *vCard in card.vCards) {
            [db executeUpdate:@"insert or replace into VCards(id, cardId, personImage, fullName, email, phone, version, vCardData) values(?,?,?,?,?,?,?,?)", @(vCard.id), vCard.cardId, vCard.personImage, vCard.fullName, vCard.email, vCard.phone, @(vCard.version), vCard.vCardData];
        }
    }];
}


- (void)addCard:(PBCard *)card forUser:(NSInteger)userId {
    [self runDatabaseBlockInTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSUInteger cardsCount = [db intForQuery:@"select count(cardId) from Cards where cardId=?", card.cardId];
        if (cardsCount > 0) {
            NSMutableArray *phoneIds = [NSMutableArray array];
            NSMutableArray *vCardIds = [NSMutableArray array];
            NSMutableArray *emailIds = [NSMutableArray array];
            NSMutableArray *urlIds = [NSMutableArray array];
            [db executeUpdate:@"update Cards set logo=?, title=?, summary=?, version=?, shortInfo=?  where cardId=?", card.logo, card.title, card.summary, @(card.version), @(card.shortInfo), card.cardId];
            for (PBCardPhone *phone in card.phones) {
                [phoneIds addObject:@(phone.id)];
                NSUInteger count = (NSUInteger) [db intForQuery:@"select count(id) from Phones where id=?", @(phone.id)];
                if (count > 0) {
                    [db executeUpdate:@"update Phones set phoneType=?, phoneNumber=? where id=?", @(phone.phoneType), phone.phoneNumber, @(phone.id)];
                }
                else {
                    [db executeUpdate:@"insert or replace into Phones(id, phoneType, phoneNumber, cardId) values(?,?,?,?)", @(phone.id), @(phone.phoneType), phone.phoneNumber, card.cardId];
                }
            }
            if (phoneIds.count > 0) {
                [db executeUpdateWithInOperator:@"delete from Phones where cardId=? and id not in ([?])", card.cardId, phoneIds];
            }
            else {
                [db executeUpdate:@"delete from Phones where cardId=?", card.cardId];
            }
            for (PBCardEmail *email in card.emails) {
                [emailIds addObject:@(email.id)];
                NSUInteger count = (NSUInteger) [db intForQuery:@"select count(id) from Emails where id=?", @(email.id)];
                if (count > 0) {
                    [db executeUpdate:@"update Emails set emailType=?, email=?where id=?", @(email.emailType), email.email, @(email.id)];
                }
                else {
                    [db executeUpdate:@"insert or replace into Emails(id, emailType, email, cardId) values(?,?,?,?)", @(email.id), @(email.emailType), email.email, card.cardId];
                }
            }
            if (emailIds.count > 0) {
                [db executeUpdateWithInOperator:@"delete from Emails where cardId=? and id not in ([?])", card.cardId, emailIds];
            }
            else {
                [db executeUpdate:@"delete from Emails where cardId=?", card.cardId];
            }
            for (PBCardURL *url in card.urls) {
                [urlIds addObject:@(url.id)];
                NSUInteger count = (NSUInteger) [db intForQuery:@"select count(id) from URLs where id=?", @(url.id)];
                if (count > 0) {
                    [db executeUpdate:@"update URLs set urlType=?, url=? where id=?", @(url.urlType), url.url, @(url.id)];
                }
                else {
                    [db executeUpdate:@"insert or replace into URLs(id, urlType, url, cardId) values(?,?,?,?)", @(url.id), @(url.urlType), url.url, card.cardId];
                }

            }
            if (urlIds.count > 0) {
                [db executeUpdateWithInOperator:@"delete from URLs where cardId=? and id not in ([?])", card.cardId, urlIds];
            }
            else {
                [db executeUpdate:@"delete from URLs where cardId=?", card.cardId];
            }
            for (PBVCard *vCard in card.vCards) {
                [vCardIds addObject:@(vCard.id)];
                NSUInteger count = (NSUInteger) [db intForQuery:@"select count(id) from VCards where id=?", @(vCard.id)];
                if (count > 0) {
                    [db executeUpdate:@"update VCards set personImage=?, fullName=?, email=?, phone=?, version=?, vCardData=? where id=?", vCard.personImage, vCard.fullName, vCard.email, vCard.phone, @(vCard.version), vCard.vCardData, @(vCard.id)];
                }
                else {
                    [db executeUpdate:@"insert or replace into VCards(id, cardId, personImage, fullName, email, phone, version, vCardData) values(?,?,?,?,?,?,?,?)", @(vCard.id), vCard.cardId, vCard.personImage, vCard.fullName, vCard.email, vCard.phone, @(vCard.version), vCard.vCardData];
                }

            }
            if (vCardIds.count > 0) {
                [db executeUpdateWithInOperator:@"delete from VCards where cardId=? and id not in ([?])", card.cardId, vCardIds];
            }
            else {
                [db executeUpdateWithInOperator:@"delete from VCards where cardId=?", card.cardId];
            }
            // update card shares
            NSMutableArray *sharesToUser = [NSMutableArray array];
            NSMutableArray *sharesToEmail = [NSMutableArray array];
            NSMutableArray *existedGuids = [NSMutableArray array];
            NSMutableArray *existedIds = [NSMutableArray array];
            for (PBCardsShare *cardShare in card.cardShare) {
                cardShare.cardId = card.cardId;
                if (cardShare.userId == -1 && cardShare.shareGuid != nil) {
                    [sharesToEmail addObject:cardShare];
                    [existedGuids addObject:cardShare.shareGuid];
                }
                else {
                    [sharesToUser addObject:cardShare];
                    [existedIds addObject:@(cardShare.userId)];
                }
            }
            for (PBCardsShare *share in sharesToUser) {
                PBUser *user = [self databaseObjectsWithResultSet:[db executeQuery:@"select * from Users where userId=?", @(share.userId)] class:[PBUser class]].firstObject;
                if (!user) {
                    PBUser *newUser = [[PBUser alloc] init];
                    newUser.userId = share.userId;
                    newUser.email = share.email;
                    [db executeUpdate:@"insert or replace into Users(userId, fullName, email, facebookIsLinked, twitterIsLinked, gPlusIsLinked) values(?,?,?,?,?,?)", @(newUser.userId), newUser.fullName, newUser.email, @(newUser.facebookIsLinked), @(newUser.twitterIsLinked), @(newUser.gPlusIsLinked)];
                }
                NSInteger count = [db intForQuery:@"select count(id) from CardsShare where userId=? and cardId=?", @(share.userId), card.cardId];
                if(count > 0){
                    [db executeUpdate:@"update CardsShare set permission=?, email=?, version=? where userId=? and cardId=?", @(share.permission), share.email, @(share.version), @(share.userId), share.cardId];
                }
                else{
                    [db executeUpdate:@"insert or replace into CardsShare(shareGuid, cardId, userId, permission, email, version) values (?,?,?,?,?,?)", share.shareGuid, share.cardId, @(share.userId), @(share.permission), share.email, @(share.version)];
                }
            }
            for (PBCardsShare *share in sharesToEmail) {
                NSInteger count = [db intForQuery:@"select count(id) from CardsShare where shareGuid=? and cardId=?", share.shareGuid, card.cardId];
                if (count > 0) {
                    [db executeUpdate:@"update CardsShare set userId=?, permission=?, email=?, version=? where shareGuid=? and cardId=?", @(share.userId), @(share.permission), share.email, @(share.version), share.shareGuid, share.cardId];
                }
                else {
                    [db executeUpdate:@"insert or replace into CardsShare(shareGuid, cardId, userId, permission, email, version) values (?,?,?,?,?,?)", share.shareGuid, share.cardId, @(share.userId), @(share.permission), share.email, @(share.version)];
                }

            }
            if (existedGuids.count > 0) {
                [db executeUpdateWithInOperator:@"delete from CardsShare where cardId=? and userId=? and shareGuid not in ([?])", card.cardId, @(kPBDefaultUserId), existedGuids];
            }
            if (existedIds.count > 0) {
                [db executeUpdateWithInOperator:@"delete from CardsShare where cardId=? and shareGuid=? and userId not in ([?])", card.cardId, kDefaultShareGuid, existedIds];
            }
            if (card.cardShare.count == 0) {
                [db executeUpdate:@"delete from CardsShare where cardId=?", card.cardId];
            }
        }
        else {
            [db executeUpdate:@"insert or replace into Cards(cardId, logo, title, summary, version, shortInfo) values(?,?,?,?,?,?)", card.cardId, card.logo, card.title, card.summary, @(card.version), @(card.shortInfo)];
            for (PBCardPhone *phone in card.phones) {
                [db executeUpdate:@"insert or replace into Phones(id, phoneType, phoneNumber, cardId) values(?,?,?,?)", @(phone.id), @(phone.phoneType), phone.phoneNumber, card.cardId];
            }
            for (PBCardEmail *email in card.emails) {
                [db executeUpdate:@"insert or replace into Emails(id, emailType, email, cardId) values(?,?,?,?)", @(email.id), @(email.emailType), email.email, card.cardId];
            }
            for (PBCardURL *url in card.urls) {
                [db executeUpdate:@"insert or replace into URLs(id, urlType, url, cardId) values(?,?,?,?)", @(url.id), @(url.urlType), url.url, card.cardId];
            }
            for (PBVCard *vCard in card.vCards) {
                [db executeUpdate:@"insert or replace into VCards(id, cardId, personImage, fullName, email, phone, version, vCardData) values(?,?,?,?,?,?,?,?)", @(vCard.id), vCard.cardId, vCard.personImage, vCard.fullName, vCard.email, vCard.phone, @(vCard.version), vCard.vCardData];
            }

            NSMutableArray *sharesToUser = [NSMutableArray array];
            NSMutableArray *sharesToEmail = [NSMutableArray array];
            for (PBCardsShare *cardShare in card.cardShare) {
                cardShare.cardId = card.cardId;
                if (cardShare.userId == -1 && cardShare.shareGuid != nil) {
                    [sharesToEmail addObject:cardShare];
                }
                else {
                    [sharesToUser addObject:cardShare];
                }
            }
            for (PBCardsShare *share in sharesToUser) {
                PBUser *user = [self databaseObjectsWithResultSet:[db executeQuery:@"select * from Users where userId=?", @(share.userId)] class:[PBUser class]].firstObject;
                if (!user) {
                    PBUser *newUser = [[PBUser alloc] init];
                    newUser.userId = share.userId;
                    newUser.email = share.email;
                    [db executeUpdate:@"insert or replace into Users(userId, fullName, email, facebookIsLinked, twitterIsLinked, gPlusIsLinked) values(?,?,?,?,?,?)", @(newUser.userId), newUser.fullName, newUser.email, @(newUser.facebookIsLinked), @(newUser.twitterIsLinked), @(newUser.gPlusIsLinked)];
                }
                [db executeUpdate:@"insert or replace into CardsShare(shareGuid, cardId, userId, permission, email, version) values (?,?,?,?,?,?)", share.shareGuid, share.cardId, @(share.userId), @(share.permission), share.email, @(share.version)];
            }
            for (PBCardsShare *share in sharesToEmail) {
                [db executeUpdate:@"insert or replace into CardsShare(shareGuid, cardId, userId, permission, email, version) values (?,?,?,?,?,?)", share.shareGuid, share.cardId, @(share.userId), @(share.permission), share.email, @(share.version)];
            }
        }
        NSInteger permissionsCount = [db intForQuery:@"select count(id) from Permissions where cardId=? and userId=?", card.cardId, @(userId)];
        if (permissionsCount > 0) {
            [db executeUpdate:@"update Permissions set permission=? where cardId=? and userId=?", @(card.permission), card.cardId, @(userId)];
        }
        else {
            [db executeUpdate:@"insert or replace into Permissions(userId, cardId, permission) values(?,?,?)", @(userId), card.cardId, @(card.permission)];
        }
    }];
}


- (void)updateCard:(PBCard *)card {
    [self runDatabaseBlockInTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSMutableArray *phoneIds = [NSMutableArray array];
        NSMutableArray *vCardIds = [NSMutableArray array];
        NSMutableArray *emailIds = [NSMutableArray array];
        NSMutableArray *urlIds = [NSMutableArray array];
        [db executeUpdate:@"update Cards set logo=?, title=?, summary=?, version=?, shortInfo=?  where cardId=?", card.logo, card.title, card.summary, @(card.version), @(card.shortInfo), card.cardId];
        for (PBCardPhone *phone in card.phones) {
            [phoneIds addObject:@(phone.id)];
            NSUInteger count = (NSUInteger) [db intForQuery:@"select count(id) from Phones where id=?", @(phone.id)];
            if (count > 0) {
                [db executeUpdate:@"update Phones set phoneType=?, phoneNumber=? where id=?", @(phone.phoneType), phone.phoneNumber, @(phone.id)];
            }
            else {
                [db executeUpdate:@"insert or replace into Phones(id, phoneType, phoneNumber, cardId) values(?,?,?,?)", @(phone.id), @(phone.phoneType), phone.phoneNumber, card.cardId];
            }
        }
        if (phoneIds.count > 0) {
            [db executeUpdateWithInOperator:@"delete from Phones where cardId=? and id not in ([?])", card.cardId, phoneIds];
        }
        else {
            [db executeUpdate:@"delete from Phones where cardId=?", card.cardId];
        }
        for (PBCardEmail *email in card.emails) {
            [emailIds addObject:@(email.id)];
            NSUInteger count = (NSUInteger) [db intForQuery:@"select count(id) from Emails where id=?", @(email.id)];
            if (count > 0) {
                [db executeUpdate:@"update Emails set emailType=?, email=?where id=?", @(email.emailType), email.email, @(email.id)];
            }
            else {
                [db executeUpdate:@"insert or replace into Emails(id, emailType, email, cardId) values(?,?,?,?)", @(email.id), @(email.emailType), email.email, card.cardId];
            }
        }
        if (emailIds.count > 0) {
            [db executeUpdateWithInOperator:@"delete from Emails where cardId=? and id not in ([?])", card.cardId, emailIds];
        }
        else {
            [db executeUpdate:@"delete from Emails where cardId=?", card.cardId];
        }
        for (PBCardURL *url in card.urls) {
            [urlIds addObject:@(url.id)];
            NSUInteger count = (NSUInteger) [db intForQuery:@"select count(id) from URLs where id=?", @(url.id)];
            if (count > 0) {
                [db executeUpdate:@"update URLs set urlType=?, url=? where id=?", @(url.urlType), url.url, @(url.id)];
            }
            else {
                [db executeUpdate:@"insert or replace into URLs(id, urlType, url, cardId) values(?,?,?,?)", @(url.id), @(url.urlType), url.url, card.cardId];
            }

        }
        if (urlIds.count > 0) {
            [db executeUpdateWithInOperator:@"delete from URLs where cardId=? and id not in ([?])", card.cardId, urlIds];
        }
        else {
            [db executeUpdate:@"delete from URLs where cardId=?", card.cardId];
        }
        for (PBVCard *vCard in card.vCards) {
            [vCardIds addObject:@(vCard.id)];
            NSUInteger count = (NSUInteger) [db intForQuery:@"select count(id) from VCards where id=?", @(vCard.id)];
            if (count > 0) {
                [db executeUpdate:@"update VCards set personImage=?, fullName=?, email=?, phone=?, version=?, vCardData=? where id=?", vCard.personImage, vCard.fullName, vCard.email, vCard.phone, @(vCard.version), vCard.vCardData, @(vCard.id)];
            }
            else {
                [db executeUpdate:@"insert or replace into VCards(id, cardId, personImage, fullName, email, phone, version, vCardData) values(?,?,?,?,?,?,?,?)", @(vCard.id), vCard.cardId, vCard.personImage, vCard.fullName, vCard.email, vCard.phone, @(vCard.version), vCard.vCardData];
            }

        }
        if (vCardIds.count > 0) {
            [db executeUpdateWithInOperator:@"delete from VCards where cardId=? and id not in ([?])", card.cardId, vCardIds];
        }
        else {
            [db executeUpdateWithInOperator:@"delete from VCards where cardId=?", card.cardId];
        }
    }];
}


- (void)updateCard:(PBCard *)card forUser:(NSInteger)userId {
    [self runDatabaseBlockInTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSMutableArray *phoneIds = [NSMutableArray array];
        NSMutableArray *vCardIds = [NSMutableArray array];
        NSMutableArray *emailIds = [NSMutableArray array];
        NSMutableArray *urlIds = [NSMutableArray array];
        [db executeUpdate:@"update Cards set logo=?, title=?, summary=?, version=?, shortInfo=?  where cardId=?", card.logo, card.title, card.summary, @(card.version), @(card.shortInfo), card.cardId];
        for (PBCardPhone *phone in card.phones) {
            [phoneIds addObject:@(phone.id)];
            NSUInteger count = (NSUInteger) [db intForQuery:@"select count(id) from Phones where id=?", @(phone.id)];
            if (count > 0) {
                [db executeUpdate:@"update Phones set phoneType=?, phoneNumber=? where id=?", @(phone.phoneType), phone.phoneNumber, @(phone.id)];
            }
            else {
                [db executeUpdate:@"insert or replace into Phones(id, phoneType, phoneNumber, cardId) values(?,?,?,?)", @(phone.id), @(phone.phoneType), phone.phoneNumber, card.cardId];
            }
        }
        if (phoneIds.count > 0) {
            [db executeUpdateWithInOperator:@"delete from Phones where cardId=? and id not in ([?])", card.cardId, phoneIds];
        }
        else {
            [db executeUpdate:@"delete from Phones where cardId=?", card.cardId];
        }
        for (PBCardEmail *email in card.emails) {
            [emailIds addObject:@(email.id)];
            NSUInteger count = (NSUInteger) [db intForQuery:@"select count(id) from Emails where id=?", @(email.id)];
            if (count > 0) {
                [db executeUpdate:@"update Emails set emailType=?, email=?where id=?", @(email.emailType), email.email, @(email.id)];
            }
            else {
                [db executeUpdate:@"insert or replace into Emails(id, emailType, email, cardId) values(?,?,?,?)", @(email.id), @(email.emailType), email.email, card.cardId];
            }
        }
        if (emailIds.count > 0) {
            [db executeUpdateWithInOperator:@"delete from Emails where cardId=? and id not in ([?])", card.cardId, emailIds];
        }
        else {
            [db executeUpdate:@"delete from Emails where cardId=?", card.cardId];
        }
        for (PBCardURL *url in card.urls) {
            [urlIds addObject:@(url.id)];
            NSUInteger count = (NSUInteger) [db intForQuery:@"select count(id) from URLs where id=?", @(url.id)];
            if (count > 0) {
                [db executeUpdate:@"update URLs set urlType=?, url=? where id=?", @(url.urlType), url.url, @(url.id)];
            }
            else {
                [db executeUpdate:@"insert or replace into URLs(id, urlType, url, cardId) values(?,?,?,?)", @(url.id), @(url.urlType), url.url, card.cardId];
            }

        }
        if (urlIds.count > 0) {
            [db executeUpdateWithInOperator:@"delete from URLs where cardId=? and id not in ([?])", card.cardId, urlIds];
        }
        else {
            [db executeUpdate:@"delete from URLs where cardId=?", card.cardId];
        }
        for (PBVCard *vCard in card.vCards) {
            [vCardIds addObject:@(vCard.id)];
            NSUInteger count = (NSUInteger) [db intForQuery:@"select count(id) from VCards where id=?", @(vCard.id)];
            if (count > 0) {
                [db executeUpdate:@"update VCards set personImage=?, fullName=?, email=?, phone=?, version=?, vCardData=? where id=?", vCard.personImage, vCard.fullName, vCard.email, vCard.phone, @(vCard.version), vCard.vCardData, @(vCard.id)];
            }
            else {
                [db executeUpdate:@"insert or replace into VCards(id, cardId, personImage, fullName, email, phone, version, vCardData) values(?,?,?,?,?,?,?,?)", @(vCard.id), vCard.cardId, vCard.personImage, vCard.fullName, vCard.email, vCard.phone, @(vCard.version), vCard.vCardData];
            }

        }
        if (vCardIds.count > 0) {
            [db executeUpdateWithInOperator:@"delete from VCards where cardId=? and id not in ([?])", card.cardId, vCardIds];
        }
        else {
            [db executeUpdateWithInOperator:@"delete from VCards where cardId=?", card.cardId];
        }
        // update card shares
        NSMutableArray *sharesToUser = [NSMutableArray array];
        NSMutableArray *sharesToEmail = [NSMutableArray array];
        NSMutableArray *existedGuids = [NSMutableArray array];
        NSMutableArray *existedIds = [NSMutableArray array];
        for (PBCardsShare *cardShare in card.cardShare) {
            cardShare.cardId = card.cardId;
            if (cardShare.userId == -1 && cardShare.shareGuid != nil) {
                [sharesToEmail addObject:cardShare];
                [existedGuids addObject:cardShare.shareGuid];
            }
            else {
                [sharesToUser addObject:cardShare];
                [existedIds addObject:@(cardShare.userId)];
            }
        }
        for (PBCardsShare *share in sharesToUser) {
            PBUser *user = [self databaseObjectsWithResultSet:[db executeQuery:@"select * from Users where userId=?", @(share.userId)] class:[PBUser class]].firstObject;
            if (!user) {
                PBUser *newUser = [[PBUser alloc] init];
                newUser.userId = share.userId;
                newUser.email = share.email;
                [db executeUpdate:@"insert or replace into Users(userId, fullName, email, facebookIsLinked, twitterIsLinked, gPlusIsLinked) values(?,?,?,?,?,?)", @(newUser.userId), newUser.fullName, newUser.email, @(newUser.facebookIsLinked), @(newUser.twitterIsLinked), @(newUser.gPlusIsLinked)];
            }
            NSInteger count = [db intForQuery:@"select count(id) from CardsShare where userId=? and cardId=?", @(share.userId), card.cardId];
            if(count > 0){
                [db executeUpdate:@"update CardsShare set permission=?, email=?, version=? where userId=? and cardId=?", @(share.permission), share.email, @(share.version), @(share.userId), share.cardId];
            }
            else{
                [db executeUpdate:@"insert or replace into CardsShare(shareGuid, cardId, userId, permission, email, version) values (?,?,?,?,?,?)", share.shareGuid, share.cardId, @(share.userId), @(share.permission), share.email, @(share.version)];
            }
        }
        for (PBCardsShare *share in sharesToEmail) {
            NSInteger count = [db intForQuery:@"select count(id) from CardsShare where shareGuid=? and cardId=?", share.shareGuid, card.cardId];
            if (count > 0) {
                [db executeUpdate:@"update CardsShare set userId=?, permission=?, email=?, version=? where shareGuid=? and cardId=?", @(share.userId), @(share.permission), share.email, @(share.version), share.shareGuid, share.cardId];
            }
            else {
                [db executeUpdate:@"insert or replace into CardsShare(shareGuid, cardId, userId, permission, email, version) values (?,?,?,?,?,?)", share.shareGuid, share.cardId, @(share.userId), @(share.permission), share.email, @(share.version)];
            }

        }
        if (existedGuids.count > 0) {
            [db executeUpdateWithInOperator:@"delete from CardsShare where cardId=? and userId=? and shareGuid not in ([?])", card.cardId, @(kPBDefaultUserId), existedGuids];
        }
        if (existedIds.count > 0) {
            [db executeUpdateWithInOperator:@"delete from CardsShare where cardId=? and shareGuid=? and userId not in ([?])", card.cardId, kDefaultShareGuid, existedIds];
        }
        if (card.cardShare.count == 0) {
            [db executeUpdate:@"delete from CardsShare where cardId=?", card.cardId];
        }
    }];
}


- (void)deleteCard:(PBCard *)card fromUser:(NSInteger)userId {
    [self runDatabaseBlock:^(FMDatabase *db) {
        [db executeUpdate:@"delete from Permissions where cardId=? and userId=?", card.cardId, @(userId)];
        [db executeUpdate:@"delete from Cards where cardId=?", card.cardId];
    }];

}


- (void)cardHistoryExist:(NSString *)cardId forUser:(NSInteger)userId callback:(void (^)(BOOL exist, PBCardHistory *cardHistory))callback {
    [self runFetchForClass:[PBCardHistory class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select * from CardsHistory where cardId=? and userId=?", cardId, @(userId)];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback((results != nil && results.count > 0), results.firstObject);
        }
    }];
}


- (void)addCardHistory:(PBCardHistory *)cardHistory toUser:(NSInteger)userId {
    [self runDatabaseBlock:^(FMDatabase *db) {
        NSInteger count = [db intForQuery:@"select count(cardId) from CardsHistory where cardId=? and userId=?", cardHistory.cardId, @(userId)];
        if(count > 0){
            [db executeUpdate:@"update CardsHistory set visitDateTimeStamp=?, isFavourite=?, latitude=?, longitude=?, distance=? where cardId=? and userId=?", @([cardHistory.visitDate timeIntervalSince1970]), @(cardHistory.isFavourite), @(cardHistory.latitude), @(cardHistory.longitude), @(cardHistory.distance), cardHistory.cardId, @(userId)];
        }
        else{
                    [db executeUpdate:@"insert or replace into CardsHistory(cardId, userId, visitDateTimeStamp, isFavourite, latitude, longitude, distance) values(?,?,?,?,?,?,?) ", cardHistory.cardId, @(userId), @([cardHistory.visitDate timeIntervalSince1970]), @(cardHistory.isFavourite), @(cardHistory.latitude), @(cardHistory.longitude), @(cardHistory.distance)];
        }

    }];
}


- (void)updateCardHistory:(PBCardHistory *)cardHistory forUser:(NSInteger)userId {
    [self runDatabaseBlock:^(FMDatabase *db) {
        [db executeUpdate:@"update CardsHistory set visitDateTimeStamp=?, isFavourite=?, latitude=?, longitude=?, distance=? where cardId=? and userId=?", @([cardHistory.visitDate timeIntervalSince1970]), @(cardHistory.isFavourite), @(cardHistory.latitude), @(cardHistory.longitude), @(cardHistory.distance), cardHistory.cardId, @(userId)];
    }];

}


- (void)deleteCardHistory:(PBCardHistory *)cardHistory forUser:(NSInteger)userId {
    [self runDatabaseBlock:^(FMDatabase *db) {
        [db executeUpdate:@"delete from CardsHistory where cardId=? and userId=?", cardHistory.cardId, @(userId)];
    }];
}


- (void)beaconExist:(PBBeacon *)beacon callback:(void (^)(BOOL exist))callback {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSInteger count = [db intForQuery:@"select count(beaconUid) as count from Beacons where beaconUid=?", beacon.beaconUid];
        dispatch_async(dispatch_get_main_queue(), ^() {
            if (callback) {
                callback((count == 1));
            }
        });
    }];
}


- (void)getAllBeaconsForUser:(NSInteger)userId withCallback:(void (^)(NSArray *beacons))callback {
    [self runFetchForClass:[PBBeacon class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select b.beaconUid, b.major, b.minor, b.power, count(b.beaconUid) as linkedCardsCount from Beacons as b join BeaconsCards as bc on b.beaconUid=bc.beaconId join Permissions as p on bc.cardId=p.cardId where p.userId=? group by b.beaconUid", @(userId)];
    }    fetchResultsBlock:^(NSArray *results) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_group_t group = dispatch_group_create();
            for (PBBeacon *beacon in results) {
                dispatch_group_enter(group);
                [self runFetchForClass:[PBBeaconCard class] fetchBlock:^FMResultSet *(FMDatabase *db) {
                    return [db executeQuery:@"select cardId as cardGuid, state as isActive from BeaconsCards where beaconId=?", beacon.beaconUid];
                }    fetchResultsBlock:^(NSArray *cards) {
                    beacon.cards = cards;
                    dispatch_group_leave(group);
                }];
            }
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (callback) {
                    callback(results);
                }
            });
        });
    }];

}


- (void)getBeaconsForCard:(PBCard *)card callback:(void (^)(NSArray *beacons))callback {
    [self runFetchForClass:[PBBeacon class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select bc.beaconId as beaconUid, bc.state, b.major, b.minor, b.power, count(bc1.cardId) as linkedCardsCount from BeaconsCards as bc join Beacons as b on bc.beaconId=b.beaconUid join BeaconsCards as bc1 on bc.beaconId=bc1.beaconId where bc.cardId=? group by bc.beaconId", card.cardId];
    }    fetchResultsBlock:^(NSArray *results) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_group_t group = dispatch_group_create();
            for (PBBeacon *beacon in results) {
                dispatch_group_enter(group);
                [self runFetchForClass:[PBBeaconCard class] fetchBlock:^FMResultSet *(FMDatabase *db) {
                    return [db executeQuery:@"select cardId as cardGuid, state as isActive from BeaconsCards where beaconId=?", beacon.beaconUid];
                }    fetchResultsBlock:^(NSArray *cards) {
                    beacon.cards = cards;
                    dispatch_group_leave(group);
                }];
            }
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (callback) {
                    callback(results);
                }
            });
        });
    }];
}


- (void)getCardsForBeacon:(PBBeacon *)beacon callback:(void (^)(NSArray *cards))callback {
    [self runFetchForClass:[PBCard class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select c.cardId, c.title, c.summary, c.logo, c.version, bc.state as isActive, count(bc1.beaconId) as beaconsCount, p.permission from BeaconsCards as bc join Cards as c on bc.cardId=c.cardId join BeaconsCards as bc1 on c.cardId=bc1.cardId join Permissions as p on p.cardId=c.cardId where bc.beaconId=? group by bc.cardId", beacon.beaconUid];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback(results);
        }
    }];
}


- (void)getBeaconByUid:(NSString *)beaconUid callback:(void (^)(PBBeacon *beacon))callback {
    [self runFetchForClass:[PBBeacon class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select * from Beacons where beaconUid=?", beaconUid];
    }    fetchResultsBlock:^(NSArray *results) {
        PBBeacon *beacon = results.firstObject;
        if (beacon) {
            [self runFetchForClass:[PBBeaconCard class] fetchBlock:^FMResultSet *(FMDatabase *db) {
                return [db executeQuery:@"select cardId as cardGuid, state as isActive from BeaconsCards where beaconId=?", beaconUid];
            }    fetchResultsBlock:^(NSArray *linkedCardsResults) {
                beacon.cards = linkedCardsResults;
                if (callback) {
                    callback(beacon);
                }
            }];
        }
        else {
            if (callback) {
                callback(nil);
            }
        }
    }];
}


- (void)addBeacon:(PBBeacon *)beacon {
    [self runDatabaseBlockInTransaction:^(FMDatabase *db, BOOL *rollaback) {
        [db executeUpdate:@"insert or replace into Beacons(beaconUid, major, minor, power) values(?,?,?,?)", beacon.beaconUid, @(beacon.major), @(beacon.minor), @(beacon.power)];
        for (PBBeaconCard *beaconCard in beacon.cards) {
            [db executeUpdate:@"insert or replace into BeaconsCards(beaconId, cardId, state) values(?,?,?)", beacon.beaconUid, beaconCard.cardGuid, @(beaconCard.isActive)];
        }
    }];

}


- (void)addBeacon:(PBBeacon *)beacon toCard:(PBCard *)card {
    [self runDatabaseBlockInTransaction:^(FMDatabase *db, BOOL *rollaback) {
        [db executeUpdate:@"insert or replace into Beacons(beaconUid, major, minor, power, version) values(?,?,?,?,?)", beacon.beaconUid, @(beacon.major), @(beacon.minor), @(beacon.power), @(beacon.version)];
        [db executeUpdate:@"insert or replace into BeaconsCards(beaconId, cardId, state) values(?,?,?)", beacon.beaconUid, card.cardId, @(beacon.state)];
    }];

}


- (void)updateBeacon:(PBBeacon *)beacon {
    [self runDatabaseBlockInTransaction:^(FMDatabase *db, BOOL *rollaback) {
        __block NSMutableArray *cardGuids = [NSMutableArray array];
        [db executeUpdate:@"update Beacons set major=?, minor=?, power=?, version=? where beaconUid=?", @(beacon.major), @(beacon.minor), @(beacon.power), @(beacon.version), beacon.beaconUid];
        [beacon.cards enumerateObjectsUsingBlock:^(PBBeaconCard *object, NSUInteger index, BOOL *stop) {
            [cardGuids addObject:object.cardGuid];
            NSUInteger count = (NSUInteger) [db intForQuery:@"select count(id) from BeaconsCards where beaconId=? and cardId=?", beacon.beaconUid, object.cardGuid];
            if (count > 0) {
                [db executeUpdate:@"update BeaconsCards set state=? where beaconId=? and cardId=?", @(object.isActive), beacon.beaconUid, object.cardGuid];
            }
            else {
                [db executeUpdate:@"insert or replace into BeaconsCards(beaconId, cardId, state) values(?,?,?)", beacon.beaconUid, object.cardGuid, @(object.isActive)];
            }
        }];
        if (cardGuids.count > 0) {
            [db executeUpdateWithInOperator:@"delete from BeaconsCards where beaconId=? and cardId not in ([?])", beacon.beaconUid, cardGuids];
        }
        else {
            [db executeUpdate:@"delete from BeaconsCards where beaconId=?", beacon.beaconUid];
        }
    }];
}


- (void)deleteBeacon:(PBBeacon *)beacon {
    [self runDatabaseBlock:^(FMDatabase *db) {
        [db executeUpdate:@"delete from Beacons where beaconUid=?", beacon.beaconUid];
    }];

}


- (void)linkBeacon:(PBBeacon *)beacon toCard:(PBCard *)card {
    [self runDatabaseBlock:^(FMDatabase *db) {
        [db executeUpdate:@"insert or replace into BeaconsCards(beaconId, cardId, state) values(?,?,?)", beacon.beaconUid, card.cardId, @(beacon.state)];
    }];
}


- (void)unlinkBeacon:(PBBeacon *)beacon fromCard:(PBCard *)card {
    [self runDatabaseBlockInTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"delete from BeaconsCards where beaconId=?, cardId=?", beacon.beaconUid, card.cardId];
        beacon.linkedCardsCount--;
        if (beacon.linkedCardsCount == 0) {
            [db executeUpdate:@"delete from Beacons where beaconUid=?", beacon.beaconUid];
        }
    }];
}


- (void)vCardExist:(PBVCard *)vCard callback:(void (^)(BOOL exist, PBVCard *existedVCard))callback {
    [self runFetchForClass:[PBVCard class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select * from VCards where id=?", @(vCard.id)];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback((results != nil && results.count > 0), results.firstObject);
        }
    }];
}


- (void)getVCardsForCardGuid:(NSString *)cardId callback:(void (^)(NSArray *vCards))callback {
    [self runFetchForClass:[PBVCard class] fetchBlock:^FMResultSet *(FMDatabase *db) {
        return [db executeQuery:@"select * from VCards where cardId=?", cardId];
    }    fetchResultsBlock:^(NSArray *results) {
        if (callback) {
            callback(results);
        }
    }];
}


/*- (void)addVCard:(PBVCard *)vCard {
    [self runDatabaseBlock:^(FMDatabase *db) {
        [db executeUpdate:@"insert or replace into VCards(id, cardId, personImage, fullName, email, phone, version, vCardFileId) values(?,?,?,?,?,?,?,?)", @(vCard.id), vCard.cardId, vCard.personImage, vCard.fullName, vCard.email, vCard.phone, @(vCard.version), vCard.vCardFileId];
    }];
}


- (void)updateVCard:(PBVCard *)vCard {
    [self runDatabaseBlock:^(FMDatabase *db) {
        [db executeUpdate:@"update VCards set personImage=?, fullName=?, email=?, phone=?, version=? where id=?", vCard.personImage, vCard.fullName, vCard.email, vCard.phone, @(vCard.version), @(vCard.id)];
    }];
}


- (void)deleteVCard:(PBVCard *)vCard {
    [self runDatabaseBlock:^(FMDatabase *db) {
        [db executeUpdate:@"delete from VCards where id=?", @(vCard.id)];
    }];
}*/


#pragma mark - Helper methods


- (void)runDatabaseBlock:(PBDatabaseUpdateBlock)databaseBlock {
    [self.databaseQueue inDatabase:databaseBlock];
}


- (void)runDatabaseBlockInTransaction:(PBDatabaseTransactionsUpdateBlock)databaseBlock {
    [self.databaseQueue inTransaction:databaseBlock];
}


- (void)runFetchForClass:(Class)databaseObjectClass fetchBlock:(PBDatabaseFetchBlock)fetchBlock fetchResultsBlock:(PBDatabaseFetchResultsBlock)fetchResultsBlock {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = fetchBlock(db);
        NSArray *fetchedObjects = [self databaseObjectsWithResultSet:resultSet class:databaseObjectClass];
        if (fetchResultsBlock) {
            dispatch_async(dispatch_get_main_queue(), ^() {
                fetchResultsBlock(fetchedObjects);
            });
        }
    }];
}


- (NSArray *)databaseObjectsWithResultSet:(FMResultSet *)set class:(Class)class {
    NSMutableArray *results = [NSMutableArray array];
    while ([set next]) {
        if ([class isSubclassOfClass:[PBBaseModel class]]) {
            id instance = [((PBBaseModel *) [class alloc]) initWithDatabaseResultSet:set];
            [results addObject:instance];
        }
    }

    return results;
}

@end