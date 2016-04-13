//
//  PBMoreTableViewController.m
//  ProjectBeacon
//
//  Created by Oleksandr Malyarenko on 1/5/16.
//  Copyright © 2016 Onlinico. All rights reserved.
//

#import "PBMoreTableViewController.h"
#import "PBMoreToTabSegue.h"
#import "PBApplicationFacade.h"
#import "PBAccountViewController.h"
#import "PBMoreViewController.h"
#import "PBBeaconDetailViewController.h"
#import "PBMoreTableViewCell.h"


@interface PBMoreTableViewController ()


@property (nonatomic, strong) PBApplicationFacade *facade;

@end


@implementation PBMoreTableViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.facade = [PBApplicationFacade sharedManager];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PBMoreTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MoreTableCell"];
    [cell setEnabled:YES];
    switch (indexPath.row) {
        case 0: {
            cell.cellText.text = NSLocalizedString(@"Scanning", @"Scanning");
            cell.cellImage.image = [UIImage imageNamed:@"scanning"];
            cell.cellSwitch.hidden = NO;
            cell.cellSwitch.on = [self.facade isWatching];
            [cell.cellSwitch addTarget:self action:@selector(switchWatching:) forControlEvents:UIControlEventValueChanged];
            break;
        }
        case 1: {
            cell.cellText.text = NSLocalizedString(@"History", @"History");
            cell.cellImage.image = [UIImage imageNamed:@"history"];
            cell.cellSwitch.hidden = YES;
            break;
        }
        case 2: {
            cell.cellText.text = NSLocalizedString(@"Favorites", @"Favorites");
            cell.cellImage.image = [UIImage imageNamed:@"favorites"];
            cell.cellSwitch.hidden = YES;
            break;
        }
        case 3: {
            cell.cellText.text = NSLocalizedString(@"My Cards", @"My Cards");
            cell.cellImage.image = [UIImage imageNamed:@"my_cards"];
            cell.cellSwitch.hidden = YES;
            if (self.facade.isAnonymus) {
                [cell setEnabled:NO];
            }
            break;
        }
        case 4: {
            cell.cellText.text = NSLocalizedString(@"My Beacons", @"My Beacons");
            cell.cellImage.image = [UIImage imageNamed:@"my_beacons"];
            cell.cellSwitch.hidden = YES;
            if (self.facade.isAnonymus) {
                [cell setEnabled:NO];
            }
            break;
        }
        case 5: {
            cell.cellText.text = NSLocalizedString(@"Device As Beacon", @"Device As Beacon");
            cell.cellImage.image = [UIImage imageNamed:@"device_as_beacon"];
            cell.cellSwitch.hidden = NO;
            cell.cellSwitch.on = [self.facade isPublishing];
                        [cell.cellSwitch addTarget:self action:@selector(switchPublishing:) forControlEvents:UIControlEventValueChanged];
            if (self.facade.isAnonymus) {
                [cell setEnabled:NO];
            }
            break;
        }
        case 6: {
            cell.cellText.text = NSLocalizedString(@"My Account", @"My Account");
            cell.cellImage.image = [UIImage imageNamed:@"account"];
            cell.cellSwitch.hidden = YES;
            if (self.facade.isAnonymus) {
                [cell setEnabled:NO];
            }
            break;
        }
        default:
            break;
    }
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
        case 1:
        case 2:{
            [self performSegueWithIdentifier:@"MoreToTabSegue" sender:self];
        }
        case 3: {
            if (!self.facade.isAnonymus) {
                [self performSegueWithIdentifier:@"MoreToTabSegue" sender:self];
            }
            break;
        }
        case 4:{
            if (!self.facade.isAnonymus) {
                [self performSegueWithIdentifier:@"MoreToMyBeaconsSegue" sender:self];
            }
            break;
        }
        case 5:{
            if (!self.facade.isAnonymus) {
                [self performSegueWithIdentifier:@"MoreToDeviceAsBeaconSegue" sender:self];
            }
            break;
        }
        case 6:{
            if (!self.facade.isAnonymus) {
                [self performSegueWithIdentifier:@"MoreToAccountSegue" sender:self];
            }
            break;
        }
        default:
            break;
    }
}


#pragma mark - Application facade delegate methods


- (void)updateBluetoothStatus:(BOOL)status {
    [self.tableView reloadData];
}


#pragma mark - Navigation


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MoreToTabSegue"]) {
        ((PBMoreToTabSegue *) segue).index = (NSUInteger) [self.tableView indexPathForSelectedRow].row;
    }
    else if ([segue.identifier isEqualToString:@"MoreToAccountSegue"]) {
        ((PBAccountViewController *) segue.destinationViewController).user = ((PBMoreViewController *) self.parentViewController).user;
    }
    else if ([segue.identifier isEqualToString:@"MoreToDeviceAsBeaconSegue"]) {
        ((PBBeaconDetailViewController *) segue.destinationViewController).title = NSLocalizedString(@"Device as Beacon", @"Device as Beacon");
        ((PBBeaconDetailViewController *) segue.destinationViewController).deviceAsBeacon = YES;
    }
}


- (IBAction)switchWatching:(id)sender {
    UISwitch *switcher = sender;
    if (switcher.isOn) {
        switcher.on = [self.facade startWatching];
    }
    else {
        switcher.on = [self.facade stopWatching];
    }
}


- (IBAction)switchPublishing:(id)sender {
    UISwitch *switcher = sender;
    if (switcher.isOn) {
        switcher.on = [self.facade startPublishing];
    }
    else {
        switcher.on = [self.facade stopPublishing];
    }
}

@end
