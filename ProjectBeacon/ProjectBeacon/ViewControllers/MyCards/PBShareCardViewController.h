//
//  PBShareCardViewController.h
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/14/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol PBPassDataDelegate;
@class PBCardsShare;


@interface PBShareCardViewController : UIViewController


@property (nonatomic, assign) NSInteger index;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *popupContentView;
@property (weak, nonatomic) IBOutlet UIImageView *popupViewBackground;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UISwitch *ownerSwitch;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@property (nonatomic, weak) id <PBPassDataDelegate> delegate;

@property (nonatomic, strong) PBCardsShare *cardsShare;
- (IBAction)cancelAction:(id)sender;
- (IBAction)sendAction:(id)sender;
@end
