//
//  iOSListBoxWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSListBoxWrapper");

public protocol TableSourceItem
{
    var cellIdentifier: String { get }
    
    func createCell(tableView: UITableView) -> UITableViewCell;
    
    func bindCell(tableView: UITableView, cell: UITableViewCell);
    
    // Default implementation should return false
    func setCheckedState(tableView: UITableView, cell: UITableViewCell, isChecked: Bool) -> Bool
    
    // Default implementation should return -1
    func getHeightForRow(tableView: UITableView) -> CGFloat
}

// We want to use the accessory checkmark to show "selection", and not the iOS selection
// mechanism (with the blue or gray background).  That means we'll need to track our
// own "checked" state and use that to drive prescence of checkbox.
//
public class CheckableTableSourceItem
{
    var _checked = false;
    var _indexPath: NSIndexPath;
    var _tableSourceItem: TableSourceItem;
    
    public var checked: Bool { get { return _checked; } }
    
    public init(tableSourceItem: TableSourceItem, indexPath: NSIndexPath)
    {
        _tableSourceItem = tableSourceItem;
        _indexPath = indexPath;
    }
    
    public var tableSourceItem: TableSourceItem { get { return _tableSourceItem; } }
    
    public func setChecked(tableView: UITableView, isChecked: Bool)
    {
        if (_checked != isChecked)
        {
            _checked = isChecked;
            if let cell = tableView.cellForRowAtIndexPath(_indexPath)
            {
                setCheckedState(tableView, cell: cell);
            }
        }
    }
    
    public func setCheckedState(tableView: UITableView, cell: UITableViewCell)
    {
        if (!_tableSourceItem.setCheckedState(tableView, cell: cell, isChecked: self.checked))
        {
            cell.accessoryType = _checked ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None;
        }
    }
    
    public func getCell(tableView: UITableView) -> UITableViewCell
    {
        logger.debug("Getting cell for: \(_indexPath)");
        var cell = tableView.dequeueReusableCellWithIdentifier(_tableSourceItem.cellIdentifier);
        if (cell == nil)
        {
            cell = _tableSourceItem.createCell(tableView);
            // cell.SelectionStyle = UITableViewCellSelectionStyle.Blue;
        }
    
        _tableSourceItem.bindCell(tableView, cell: cell!);
        setCheckedState(tableView, cell: cell!);
    
        return cell!;
    }
    
    public func getHeightForRow(tableView: UITableView) -> CGFloat
    {
        return _tableSourceItem.getHeightForRow(tableView);
    }
}

public typealias OnSelectionChanged = (item: TableSourceItem) -> (Void);
public typealias OnItemClicked = (item: TableSourceItem) -> (Void);

public class CheckableTableSource : NSObject, UITableViewDataSource, UITableViewDelegate // UITableViewSource
{
    var _tableItems = [CheckableTableSourceItem]();
    
    var _onSelectionChanged: OnSelectionChanged?;
    var _onItemClicked: OnItemClicked?;
    var _selectionMode: ListSelectionMode;
    
    public init(selectionMode: ListSelectionMode, onSelectionChanged: OnSelectionChanged, onItemClicked: OnItemClicked)
    {
        _selectionMode = selectionMode;
        super.init();
        _onSelectionChanged = onSelectionChanged;
        _onItemClicked = onItemClicked;
    }
    
    public var selectionMode: ListSelectionMode { get { return _selectionMode; } }
    
    public var allItems: [CheckableTableSourceItem] { get { return _tableItems; } }
    public func clearAllItems() { _tableItems.removeAll(); }
    
    public var checkedItems: [CheckableTableSourceItem]
    {
        get
        {
            var checkedItems = [CheckableTableSourceItem]();
            for item in _tableItems
            {
                if (item.checked)
                {
                    checkedItems.append(item);
                }
            }
    
            return checkedItems;
        }
    }
    
    public func rowsInSection(tableview: UITableView, section: Int) -> Int
    {
        return _tableItems.count;
    }
    
    // From UITableViewDataSource
    //
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.rowsInSection(tableView, section: section);
    }
    
    public func getCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell
    {
        logger.debug("Getting cell for path: \(indexPath)");
        let item = _tableItems[indexPath.row];
        let cell = item.getCell(tableView);
        if ((_selectionMode == ListSelectionMode.None) && (_onItemClicked != nil))
        {
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator;
        }
        return cell;
    }
    
    // From UITableViewDataSource
    //
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        return getCell(tableView, indexPath: indexPath);
    }

    // !!! See if anyone uses this (doesn't seem to be part of UITableViewDataSource or UITableViewDelegate, and no used explicitly by this module...
    //
    public func getItemAtRow(indexPath: NSIndexPath) -> CheckableTableSourceItem?
    {
        if (indexPath.section == 0)
        {
            return _tableItems[indexPath.row];
        }
    
        return nil;
    }
    
    public func getHeightForRow(tableView: UITableView, indexPath: NSIndexPath) -> CGFloat
    {
        logger.debug("Getting row height for: \(indexPath)");
        let item = _tableItems[indexPath.row];
        return item.getHeightForRow(tableView);
    }
    
    // From UITableViewDelegate
    //
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return getHeightForRow(tableView, indexPath: indexPath);
    }
    
    public func rowSelected(tableView: UITableView, indexPath: NSIndexPath)
    {
        logger.debug("Row selected: \(indexPath)");
    
        tableView.deselectRowAtIndexPath(indexPath, animated: true); // normal iOS behaviour is to remove the blue highlight
    
        let selectedItem = _tableItems[indexPath.row];
    
        if ((_selectionMode == ListSelectionMode.Multiple) || ((_selectionMode == ListSelectionMode.Single) && !selectedItem.checked))
        {
            if (_selectionMode == ListSelectionMode.Single)
            {
                // Uncheck any currently checked item(s) and check the item selected
                //
                for item in _tableItems
                {
                    if (item.checked)
                    {
                        item.setChecked(tableView, isChecked: false);
                    }
                }
                selectedItem.setChecked(tableView, isChecked: true);
            }
            else
            {
                // Toggle the checked state of the item selected
                //
                selectedItem.setChecked(tableView, isChecked: !selectedItem.checked);
            }
    
            if (_onSelectionChanged != nil)
            {
                _onSelectionChanged!(item: selectedItem.tableSourceItem);
            }
        }
        else if ((_selectionMode == ListSelectionMode.None) && (_onItemClicked != nil))
        {
            _onItemClicked!(item: selectedItem.tableSourceItem);
        }
    }
    
    // From UITableViewDelegate
    //
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        return rowSelected(tableView, indexPath: indexPath);
    }
    
    public func rowDeselected(tableView: UITableView, indexPath: NSIndexPath)
    {
        logger.debug("Row deselected: \(indexPath)");
    }
    
    // From UITableViewDelegate
    //
    public func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath)
    {
        return rowDeselected(tableView, indexPath: indexPath);
    }
    
    /*
    
    public func rowHighlighted(tableView: UITableView, indexPath: NSIndexPath)
    {
        logger.debug("Row highlighted \(indexPath)");
    }
    
    // From UITableViewDelegate
    //
    func tableView(_ tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath)
    
    public func rowUnhighlighted(tableView: UITableView, indexPath: NSIndexPath)
    {
        logger.debug("Row unhighlighted: (\indexPath)");
    }

    // From UITableViewDelegate
    //
    func tableView(_ tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath)
    
    */
}

private var _cellIdentifier = "StringTableCell";

public class BindingContextAsStringTableSourceItem : TableSourceItem
{
    public var cellIdentifier: String { get { return _cellIdentifier; } }
    
    var _bindingContext: BindingContext;
    var _itemContent: String;
    
    public init(bindingContext: BindingContext, itemContent: String)
    {
        _bindingContext = bindingContext;
        _itemContent = itemContent;
    }
    
    public var bindingContext: BindingContext { get { return _bindingContext; } }
    
    public func getValue() -> JToken?
    {
        return _bindingContext.select("$data").getValue();
    }
    
    public func getSelection(selectionItem: String) -> JToken?
    {
        return _bindingContext.select(selectionItem).getValue()?.deepClone();
    }
    
    public func createCell(tableView: UITableView) -> UITableViewCell
    {
        return UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier);
    }
    
    public func bindCell(tableView: UITableView, cell: UITableViewCell)
    {
        cell.textLabel!.text = PropertyValue.expandAsString(_itemContent, bindingContext: _bindingContext);
    }
    
    public func setCheckedState(tableView: UITableView, cell: UITableViewCell, isChecked: Bool) -> Bool
    {
        return false;
    }
    
    public func getHeightForRow(tableView: UITableView) -> CGFloat
    {
        return -1;
    }
}

public class BindingContextAsCheckableStringTableSource : CheckableTableSource
{
    public override init(selectionMode: ListSelectionMode, onSelectionChanged: OnSelectionChanged, onItemClicked: OnItemClicked)
    {
        super.init(selectionMode: selectionMode, onSelectionChanged: onSelectionChanged, onItemClicked: onItemClicked);
    }
    
    public func addItem(bindingContext: BindingContext, itemContent: String, isChecked: Bool = false)
    {
        let item = BindingContextAsStringTableSourceItem(bindingContext: bindingContext, itemContent: itemContent);
        _tableItems.append(CheckableTableSourceItem(tableSourceItem: item, indexPath: NSIndexPath(forRow: _tableItems.count, inSection: 0)));
    }
}

private var commands = [CommandName.OnItemClick.Attribute, CommandName.OnSelectionChange.Attribute];

public class iOSListBoxWrapper : iOSControlWrapper
{
    var _selectionChangingProgramatically = false;
    var _localSelection: JToken?;
    var _dataSource: BindingContextAsCheckableStringTableSource!;

    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating listbox element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);

        let table = UITableView();
        self._control = table;
        
        // The "new style" reuse model doesn't seem to work with custom table cell implementations
        //
        // table.RegisterClassForCellReuse(typeof(TableCell), TableCell.CellIdentifier);
        
        let selectionMode = self.toListSelectionMode(controlSpec["select"]);
        
        _dataSource = BindingContextAsCheckableStringTableSource(selectionMode: selectionMode, onSelectionChanged: listbox_SelectionChanged, onItemClicked: listbox_ItemClicked);
        table.dataSource = _dataSource;
        table.delegate = _dataSource;
        
        processElementDimensions(controlSpec, defaultWidth: 150, defaultHeight: 50);
        applyFrameworkElementDefaults(table);
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "items", commandAttributes: commands)
        {
            processCommands(bindingSpec, commands: commands);
        
            if (bindingSpec["items"] != nil)
            {
                let itemContent = bindingSpec["itemContent"]?.asString() ?? "{$data}";
                
                processElementBoundValue(
                    "items",
                    attributeValue: bindingSpec["items"],
                    getValue: { () in self.getListboxContents(table) },
                    setValue: { (value) in self.setListboxContents(table, bindingContext: self.getValueBinding("items")!.bindingContext, itemContent: itemContent) });
            }
            
            if (bindingSpec["selection"] != nil)
            {
                let selectionItem = bindingSpec["selectionItem"]?.asString() ?? "$data";
                
                processElementBoundValue(
                    "selection",
                    attributeValue: bindingSpec["selection"],
                    getValue: { () in self.getListboxSelection(table, selectionItem: selectionItem) },
                    setValue: { (value) in self.setListboxSelection(table, selectionItem: selectionItem, selection: value) });
            }
        }
    }
    
    public func getListboxContents(tableView: UITableView) -> JToken
    {
        fatalError("getListboxContents not implemented");
    }
    
    public func setListboxContents(tableView: UITableView, bindingContext: BindingContext, itemContent: String)
    {
        logger.debug("Setting listbox contents");
    
        _selectionChangingProgramatically = true;
    
        let tableSource = tableView.dataSource! as! BindingContextAsCheckableStringTableSource;
    
        let oldCount = tableSource.allItems.count;
        tableSource.clearAllItems();
    
        let itemContexts = bindingContext.selectEach("$data");
        for itemContext in itemContexts
        {
            tableSource.addItem(itemContext, itemContent: itemContent);
        }
    
        let newCount = tableSource.allItems.count;
    
        var reloadRows = [NSIndexPath]();
        var insertRows = [NSIndexPath]();
        var deleteRows = [NSIndexPath]();
    
        let maxCount = max(newCount, oldCount);
        for (var i = 0; i < maxCount; i++)
        {
            let row = NSIndexPath(forRow: i, inSection: 0);
            if (i < min(newCount, oldCount))
            {
                reloadRows.append(row);
            }
            else if (i < newCount)
            {
                insertRows.append(row);
            }
            else
            {
                deleteRows.append(row);
            }
        }
    
        tableView.beginUpdates();
        if (reloadRows.count > 0)
        {
            tableView.reloadRowsAtIndexPaths(reloadRows, withRowAnimation: UITableViewRowAnimation.Fade);
        }
        if (insertRows.count > 0)
        {
            tableView.insertRowsAtIndexPaths(insertRows, withRowAnimation: UITableViewRowAnimation.Fade);
        }
        if (deleteRows.count > 0)
        {
            tableView.deleteRowsAtIndexPaths(deleteRows, withRowAnimation: UITableViewRowAnimation.Fade);
        }
        tableView.endUpdates(); // applies the changes
    
        if let selectionBinding = getValueBinding("selection")
        {
            selectionBinding.updateViewFromViewModel();
        }
        else if (_localSelection != nil)
        {
            // If there is not a "selection" value binding, then we use local selection state to restore the selection when
            // re-filling the list.
            //
            self.setListboxSelection(tableView, selectionItem: "$data", selection: _localSelection!);
        }
    
        _selectionChangingProgramatically = false;
    }
    
    public func getListboxSelection(tableView: UITableView, selectionItem: String) -> JToken
    {
        let tableSource = tableView.dataSource as! BindingContextAsCheckableStringTableSource;
    
        var checkedItems = tableSource.checkedItems;
    
        if (tableSource.selectionMode == ListSelectionMode.Multiple)
        {
            let array = JArray();
            for item in checkedItems
            {
                if let theItem = item.tableSourceItem as? BindingContextAsStringTableSourceItem
                {
                    array.append(theItem.getSelection(selectionItem) ?? JValue()); // C# code appended result of getSelection, which could be empty/nil - not sure JValue null is right
                }
            }
            return array;
        }
        else
        {
            if (checkedItems.count > 0)
            {
                if let theItem = checkedItems[0].tableSourceItem as? BindingContextAsStringTableSourceItem
                {
                    return (theItem.getSelection(selectionItem) ?? JValue());
                }
            }
            return JValue(false); // This is a "null" selection
        }
    }
    
    public func setListboxSelection(tableView: UITableView, selectionItem: String, selection: JToken?)
    {
        _selectionChangingProgramatically = true;
    
        let tableSource = tableView.dataSource! as! BindingContextAsCheckableStringTableSource;
    
        // Go through all values and check as appropriate
        //
        for tableSourceItem in tableSource.allItems
        {
            let listItem = tableSourceItem.tableSourceItem as! BindingContextAsStringTableSourceItem;
    
            var itemChecked = false;
    
            if let array = selection as? JArray
            {
                for item in array
                {
                    if (JToken.deepEquals(item, token2: listItem.getSelection(selectionItem)))
                    {
                        tableSourceItem.setChecked(tableView, isChecked: true);
                        itemChecked = true;
                        break;
                    }
                }
            }
            else
            {
                if (JToken.deepEquals(selection, token2: listItem.getSelection(selectionItem)))
                {
                    tableSourceItem.setChecked(tableView, isChecked: true);
                    itemChecked = true;
                }
            }
    
            if (!itemChecked)
            {
                tableSourceItem.setChecked(tableView, isChecked: false);
            }
        }
    
        _selectionChangingProgramatically = false;
    }
    
    func listbox_ItemClicked(item: TableSourceItem)
    {
        logger.debug("Listbox item clicked");
    
        let tableView: UITableView = self.control as! UITableView;
        let tableSource = tableView.dataSource! as! BindingContextAsCheckableStringTableSource;
    
        if (tableSource.selectionMode == ListSelectionMode.None)
        {
            if let listItem = item as? BindingContextAsStringTableSourceItem
            {
                if let command = getCommand(CommandName.OnItemClick)
                {
                    logger.debug("ListBox item click with command: \(command)");
    
                    // The item click command handler resolves its tokens relative to the item clicked (not the list view).
                    //
                    stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(listItem.bindingContext));
                }
            }
        }
    }
    
    func listbox_SelectionChanged(item: TableSourceItem)
    {
        logger.debug("Listbox selection changed");
    
        let tableView: UITableView = self.control as! UITableView;
        let tableSource = tableView.dataSource! as! BindingContextAsCheckableStringTableSource;
    
        if (getValueBinding("selection") != nil)
        {
            updateValueBindingForAttribute("selection");
        }
        else if (!_selectionChangingProgramatically)
        {
            _localSelection = self.getListboxSelection(tableView, selectionItem: "$data");
        }
    
        if ((!_selectionChangingProgramatically) && (tableSource.selectionMode != ListSelectionMode.None))
        {
            if let command = getCommand(CommandName.OnSelectionChange)
            {
                logger.debug("ListView selection change with command: \(command)");
    
                if (tableSource.selectionMode == ListSelectionMode.Single)
                {
                    if let listItem = item as? BindingContextAsStringTableSourceItem
                    {
                        // The selection change command handler resolves its tokens relative to the item selected when in single select mode.
                        //
                        stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(listItem.bindingContext));
                    }
                }
                else if (tableSource.selectionMode == ListSelectionMode.Multiple)
                {
                    // The selection change command handler resolves its tokens relative to the list context when in multiple select mode.
                    //
                    stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(self.bindingContext));
                }
            }
        }
    }
}
