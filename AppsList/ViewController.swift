//
//  ViewController.swift
//  AppsList
//
//  Created by Zhang Riyueming on 15/12/1.
//  Copyright © 2015年 Sowicm Right. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    
    var dataFolder : NSURL!
    var backupFolder : NSURL!
    
    var devices : NSMutableDictionary!
    
    var backupFormatter : NSDateFormatter!
    
    var appsLeft : NSMutableArray!
    
    var appsRight : NSMutableArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        dataFolder = NSURL(fileURLWithPath: paths[0]).URLByAppendingPathComponent("BackupsDiff/")

        backupFolder = NSURL(fileURLWithPath: "/Users/sowicm/Library/Application Support/MobileSync/Backup")

        backupFormatter = NSDateFormatter()
        backupFormatter.dateFormat = "yyyyMMdd-HHmmss"
        
        appsLeft = NSMutableArray()
        appsRight = NSMutableArray()
        
        readDevices()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func readDevices() {
        let file = dataFolder.URLByAppendingPathComponent("devices.plist")
        devices = NSMutableDictionary(contentsOfURL: file)
        if devices == nil
        {
            devices = NSMutableDictionary()
        }
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        switch (tableView.tag)
        {
        case 1:
            return devices.count
            
        case 2:
            return appsLeft.count
            
        case 3:
            return appsRight.count
            
        default:
            return 0
        }
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch (tableView.tag)
        {
        case 1:
            let cellView = tableView.makeViewWithIdentifier("device", owner: tableView) as! NSTableCellView
            cellView.textField!.stringValue = devices.allValues[row] as! NSString as String
            return cellView

        case 2:
            let cellView = tableView.makeViewWithIdentifier("application", owner: tableView) as! NSTableCellView
            cellView.textField!.stringValue = appsLeft[row] as! NSString as String
            return cellView
            
        case 3:
            let cellView = tableView.makeViewWithIdentifier("application", owner: tableView) as! NSTableCellView
            cellView.textField!.stringValue = appsRight[row] as! NSString as String
            return cellView
            
        default:
            return NSTableCellView()
        }
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        let tableView = notification.object as! NSTableView
        if (tableView.tag == 1)
        {
            let url = backupFolder.URLByAppendingPathComponent(devices.allKeys[tableView.selectedRow] as! String)
            let info = NSMutableDictionary(contentsOfURL: url.URLByAppendingPathComponent("Info.plist"))
            let manifest = NSMutableDictionary(contentsOfURL: url.URLByAppendingPathComponent("Manifest.plist"))
            let mani = manifest!.objectForKey("Applications") as! NSDictionary
            
            appsLeft.removeAllObjects()
            let apps = info?.objectForKey("Installed Applications") as! NSArray
            
            for (var i = 0; i < apps.count; ++i)
            {
                var hasPath = false
                let packageName = apps.objectAtIndex(i) as! NSString
                let appdic = mani.objectForKey( packageName )
                if appdic != nil
                {
                    let pathString = (appdic as! NSDictionary).objectForKey("Path")
                    if pathString != nil
                    {
                        let path = NSURL(fileURLWithPath: pathString as! String)
                        //result.appendFormat("%@\n(%@)\n", path.lastPathComponent as! NSString, packageName)
                        appsLeft.addObject(path.lastPathComponent!)
                        hasPath = true
                    }
                }
                if !hasPath
                {
                    appsLeft.addObject("[" + (packageName as String) + "]")
                }

            }
            
            //appsRight.removeAllObjects()
            
            oldApps.reloadData()
            //remainApps.reloadData()
        }
    }
    @IBAction func left2right(sender: AnyObject) {
        let indexes = oldApps.selectedRowIndexes
//        oldApps.removeRowsAtIndexes(indexes, withAnimation: NSTableViewAnimationEffectGap)
        oldApps.removeRowsAtIndexes(indexes, withAnimation:  NSTableViewAnimationOptions.EffectGap)// | NSTableViewAnimationOptions.SlideLeft)
        appsRight.addObjectsFromArray( appsLeft.objectsAtIndexes(indexes) )
        appsLeft.removeObjectsAtIndexes(indexes)
        
        remainApps.reloadData()
    }
    
    @IBAction func right2left(sender: AnyObject) {
        let indexes = remainApps.selectedRowIndexes
        //        oldApps.removeRowsAtIndexes(indexes, withAnimation: NSTableViewAnimationEffectGap)
        remainApps.removeRowsAtIndexes(indexes, withAnimation:  NSTableViewAnimationOptions.EffectGap)// | NSTableViewAnimationOptions.SlideLeft)
        appsLeft.addObjectsFromArray( appsRight.objectsAtIndexes(indexes) )
        appsRight.removeObjectsAtIndexes(indexes)
        
        oldApps.reloadData()
    }
    
    @IBAction func copyAsText(sender: AnyObject) {
        /*
        var responder = sender.nextResponder
        while (responder != nil) {
            if responder is NSTableView {
                break
            }
            responder = responder!!.nextResponder
        }
        if (responder == oldApps)
        {*/
            let indexes = oldApps.selectedRowIndexes
            let array = appsLeft.objectsAtIndexes(indexes) as NSArray
            var string = ""
            for (var i = 0; i < array.count; ++i)
            {
                string += array[i] as! String
                string += "\n"
            }
            NSLog("%@", string)
            let pb = NSPasteboard.generalPasteboard()
            pb.declareTypes([NSPasteboardTypeString], owner: self)
            pb.setString(string, forType: NSPasteboardTypeString)
        /*
        }
        else if (responder == remainApps)
        {
            
        }*/
    }
    
    @IBAction func copyAsText_remainApps(sender: AnyObject) {
        let indexes = remainApps.selectedRowIndexes
        let array = appsRight.objectsAtIndexes(indexes) as NSArray
        var string = ""
        for (var i = 0; i < array.count; ++i)
        {
            string += array[i] as! String
            string += "\n"
        }
        NSLog("%@", string)
        let pb = NSPasteboard.generalPasteboard()
        pb.declareTypes([NSPasteboardTypeString], owner: self)
        pb.setString(string, forType: NSPasteboardTypeString)
    }

    
    @IBOutlet weak var devicesView: NSTableView!
    @IBOutlet weak var oldApps: NSTableView!
    @IBOutlet weak var remainApps: NSTableView!
}

