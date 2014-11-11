//
//  RouteTableAdapter.swift
//  RouteStitch
//
//  Created by Fabian Canas on 11/11/14.
//  Copyright (c) 2014 Fabian Canas. All rights reserved.
//

import Cocoa

protocol ObjectSelector {
    var selectedObject: AnyObject? { get set }
}

protocol ObjectSelectorDelegate: NSObjectProtocol {
    func objectSelectorDidSelectObject(objectSelector: ObjectSelector, object: AnyObject?)
}

class RouteTableAdapter: NSObject, NSTableViewDataSource, NSTableViewDelegate, ObjectSelector {
    
    var selectedObject: AnyObject? {
        didSet {
            var index: Int = NSNotFound
            if selectedObject != nil {
                index = find(steps!, selectedObject as Step) ?? NSNotFound
            }
            if index == NSNotFound {
                tableView.deselectAll(nil)
            } else {
                tableView.selectRowIndexes(NSIndexSet(index: index), byExtendingSelection: false)
            }
        }
    }
    var delegate: ObjectSelectorDelegate?
    
    @IBOutlet weak var tableView: NSTableView! {
        didSet {
            tableView.backgroundColor = NSColor.clearColor()
        }
    }
    
    var steps: [Step]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return steps?.count ?? 0
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var result: NSTextField? = tableView.makeViewWithIdentifier("cellIdent", owner: self) as NSTextField?
        
        if result == nil {
            result = NSTextField(frame: NSRectFromCGRect(CGRectZero))
            result?.identifier = "cellIdent"
            result?.backgroundColor = NSColor.clearColor()
        }
        
        result?.stringValue = steps?[row].title ?? ""
        
        return result;
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        var selectedStep: Step?
        if self.tableView.selectedRow != -1 {
            selectedStep = steps![self.tableView.selectedRow]
        }
        self.delegate?.objectSelectorDidSelectObject(self, object: selectedStep)
    }
    
}
