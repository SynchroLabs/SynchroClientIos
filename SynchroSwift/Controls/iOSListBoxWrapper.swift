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
    
    func createCell(_ tableView: UITableView) -> UITableViewCell;
    
    func bindCell(_ tableView: UITableView, cell: UITableViewCell);
    
    // Default implementation should return false
    func setCheckedState(_ tableView: UITableView, cell: UITableViewCell, isChecked: Bool) -> Bool
    
    // Default implementation should return -1
    func getHeightForRow(_ tableView: UITableView) -> CGFloat
}

// We want to use the accessory checkmark to show "selection", and not the iOS selection
// mechanism (with the blue or gray background).  That means we'll need to track our
// own "checked" state and use that to drive prescence of checkbox.
//
open class CheckableTableSourceItem
{
    var _checked = false;
    var _indexPath: IndexPath;
    var _tableSourceItem: TableSourceItem;
    
    open var checked: Bool { get { return _checked; } }
    
    public init(tableSourceItem: TableSourceItem, indexPath: IndexPath)
    {
        _tableSourceItem = tableSourceItem;
        _indexPath = indexPath;
    }
    
    open var tableSourceItem: TableSourceItem { get { return _tableSourceItem; } }
    
    open func setChecked(_ tableView: UITableView, isChecked: Bool)
    {
        if (_checked != isChecked)
        {
            _checked = isChecked;
            if let cell = tableView.cellForRow(at: _indexPath)
            {
                setCheckedState(tableView, cell: cell);
            }
        }
    }
    
    open func setCheckedState(_ tableView: UITableView, cell: UITableViewCell)
    {
        if (!_tableSourceItem.setCheckedState(tableView, cell: cell, isChecked: self.checked))
        {
            cell.accessoryType = _checked ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none;
        }
    }
    
    open func getCell(_ tableView: UITableView) -> UITableViewCell
    {
        logger.debug("Getting cell for: \(_indexPath)");
        var cell = tableView.dequeueReusableCell(withIdentifier: _tableSourceItem.cellIdentifier);
        if (cell == nil)
        {
            cell = _tableSourceItem.createCell(tableView);
            // cell.SelectionStyle = UITableViewCellSelectionStyle.Blue;
        }
    
        _tableSourceItem.bindCell(tableView, cell: cell!);
        setCheckedState(tableView, cell: cell!);
    
        return cell!;
    }
    
    open func getHeightForRow(_ tableView: UITableView) -> CGFloat
    {
        return _tableSourceItem.getHeightForRow(tableView);
    }
}

public typealias OnSelectionChanged = (_ item: TableSourceItem) -> (Void);
public typealias OnItemClicked = (_ item: TableSourceItem) -> (Void);

open class CheckableTableSource : NSObject, UITableViewDataSource, UITableViewDelegate // UITableViewSource
{
    var _tableItems = [CheckableTableSourceItem]();
    
    var _onSelectionChanged: OnSelectionChanged?;
    var _onItemClicked: OnItemClicked?;
    var _selectionMode: ListSelectionMode;
    
    // This is used only in the case of non-select list view that has an onItemClicked handler (in that case only, it indicates whether
    // the accessory should be none or disclosure).
    //
    var _disclosure = false;
    
    public init(selectionMode: ListSelectionMode, onSelectionChanged: @escaping OnSelectionChanged, onItemClicked: @escaping OnItemClicked, disclosure: Bool)
    {
        _selectionMode = selectionMode;
        super.init();
        _onSelectionChanged = onSelectionChanged;
        _onItemClicked = onItemClicked;
        _disclosure = disclosure;
    }

    public init(selectionMode: ListSelectionMode, onSelectionChanged: @escaping OnSelectionChanged, onItemClicked: @escaping OnItemClicked)
    {
        _selectionMode = selectionMode;
        super.init();
        _onSelectionChanged = onSelectionChanged;
        _onItemClicked = onItemClicked;
    }

    open var selectionMode: ListSelectionMode { get { return _selectionMode; } }
    
    open var allItems: [CheckableTableSourceItem] { get { return _tableItems; } }
    open func clearAllItems() { _tableItems.removeAll(); }
    
    open var checkedItems: [CheckableTableSourceItem]
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
    
    open func rowsInSection(_ tableview: UITableView, section: Int) -> Int
    {
        return _tableItems.count;
    }
    
    // From UITableViewDataSource
    //
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.rowsInSection(tableView, section: section);
    }
    
    open func getCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell
    {
        logger.debug("Getting cell for path: \(indexPath)");
        let item = _tableItems[(indexPath as NSIndexPath).row];
        let cell = item.getCell(tableView);

        // This seems like it would work, but actually accomplishes jack shit.
        //
        cell.separatorInset = UIEdgeInsets.zero;

        // So instead we do this - from: http://stackoverflow.com/questions/18365049/is-there-a-way-to-make-uitableview-cells-in-ios-7-not-have-a-line-break-in-the-s/27626312#27626312
        
        // Remove seperator inset
        if cell.responds(to: #selector(setter: UITableViewCell.separatorInset))
        {
            cell.separatorInset = UIEdgeInsets.zero
        }
        
        // Prevent the cell from inheriting the Table View's margin settings
        if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins))
        {
            cell.preservesSuperviewLayoutMargins = false
        }
        
        // Explictly set your cell's layout margins
        if cell.responds(to: #selector(setter: UIView.layoutMargins))
        {
            cell.layoutMargins = UIEdgeInsets.zero
        }
        
        if ((_selectionMode == ListSelectionMode.none) && (_disclosure))
        {
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator;
        }

        return cell;
    }
    
    // From UITableViewDataSource
    //
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        return getCell(tableView, indexPath: indexPath);
    }

    // !!! See if anyone uses this (doesn't seem to be part of UITableViewDataSource or UITableViewDelegate, and no used explicitly by this module...
    //
    open func getItemAtRow(_ indexPath: IndexPath) -> CheckableTableSourceItem?
    {
        if ((indexPath as NSIndexPath).section == 0)
        {
            return _tableItems[(indexPath as NSIndexPath).row];
        }
    
        return nil;
    }
    
    open func getHeightForRow(_ tableView: UITableView, indexPath: IndexPath) -> CGFloat
    {
        logger.debug("Getting row height for: \(indexPath)");
        let item = _tableItems[(indexPath as NSIndexPath).row];
        return item.getHeightForRow(tableView);
    }
    
    // From UITableViewDelegate
    //
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return getHeightForRow(tableView, indexPath: indexPath);
    }
    
    open func rowSelected(_ tableView: UITableView, indexPath: IndexPath)
    {
        logger.debug("Row selected: \(indexPath)");
    
        tableView.deselectRow(at: indexPath, animated: true); // normal iOS behaviour is to remove the blue highlight
    
        let selectedItem = _tableItems[(indexPath as NSIndexPath).row];
    
        if ((_selectionMode == ListSelectionMode.multiple) || ((_selectionMode == ListSelectionMode.single) && !selectedItem.checked))
        {
            if (_selectionMode == ListSelectionMode.single)
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
                _onSelectionChanged!(selectedItem.tableSourceItem);
            }
        }
        else if ((_selectionMode == ListSelectionMode.none) && (_onItemClicked != nil))
        {
            _onItemClicked!(selectedItem.tableSourceItem);
        }
    }
    
    // From UITableViewDelegate
    //
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        return rowSelected(tableView, indexPath: indexPath);
    }
    
    open func rowDeselected(_ tableView: UITableView, indexPath: IndexPath)
    {
        logger.debug("Row deselected: \(indexPath)");
    }
    
    // From UITableViewDelegate
    //
    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
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

open class BindingContextAsStringTableSourceItem : TableSourceItem
{
    open var cellIdentifier: String { get { return _cellIdentifier; } }
    
    var _bindingContext: BindingContext;
    var _itemContent: String;
    
    public init(bindingContext: BindingContext, itemContent: String)
    {
        _bindingContext = bindingContext;
        _itemContent = itemContent;
    }
    
    open var bindingContext: BindingContext { get { return _bindingContext; } }
    
    open func getValue() -> JToken?
    {
        return _bindingContext.select("$data").getValue();
    }
    
    open func getSelection(_ selectionItem: String) -> JToken?
    {
        return _bindingContext.select(selectionItem).getValue()?.deepClone();
    }
    
    open func createCell(_ tableView: UITableView) -> UITableViewCell
    {
        return UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier);
    }
    
    open func bindCell(_ tableView: UITableView, cell: UITableViewCell)
    {
        cell.textLabel!.text = PropertyValue.expandAsString(_itemContent, bindingContext: _bindingContext);
    }
    
    open func setCheckedState(_ tableView: UITableView, cell: UITableViewCell, isChecked: Bool) -> Bool
    {
        return false;
    }
    
    open func getHeightForRow(_ tableView: UITableView) -> CGFloat
    {
        return -1;
    }
}

open class BindingContextAsCheckableStringTableSource : CheckableTableSource
{
    public override init(selectionMode: ListSelectionMode, onSelectionChanged: @escaping OnSelectionChanged, onItemClicked: @escaping OnItemClicked)
    {
        super.init(selectionMode: selectionMode, onSelectionChanged: onSelectionChanged, onItemClicked: onItemClicked);
    }
    
    open func addItem(_ bindingContext: BindingContext, itemContent: String, isChecked: Bool = false)
    {
        let item = BindingContextAsStringTableSourceItem(bindingContext: bindingContext, itemContent: itemContent);
        _tableItems.append(CheckableTableSourceItem(tableSourceItem: item, indexPath: IndexPath(row: _tableItems.count, section: 0)));
    }
}

private var commands = [CommandName.OnItemClick.Attribute, CommandName.OnSelectionChange.Attribute];

open class iOSListBoxWrapper : iOSControlWrapper
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
        
        let selectionMode = toListSelectionMode(processElementProperty(controlSpec, attributeName: "select", setValue: nil));
        
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
    
    open func getListboxContents(_ tableView: UITableView) -> JToken
    {
        fatalError("getListboxContents not implemented");
    }
    
    open func setListboxContents(_ tableView: UITableView, bindingContext: BindingContext, itemContent: String)
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
    
        var reloadRows = [IndexPath]();
        var insertRows = [IndexPath]();
        var deleteRows = [IndexPath]();
    
        let maxCount = max(newCount, oldCount);
        for i in 0 ..< maxCount
        {
            let row = IndexPath(row: i, section: 0);
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
            tableView.reloadRows(at: reloadRows, with: UITableViewRowAnimation.fade);
        }
        if (insertRows.count > 0)
        {
            tableView.insertRows(at: insertRows, with: UITableViewRowAnimation.fade);
        }
        if (deleteRows.count > 0)
        {
            tableView.deleteRows(at: deleteRows, with: UITableViewRowAnimation.fade);
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
    
    open func getListboxSelection(_ tableView: UITableView, selectionItem: String) -> JToken
    {
        let tableSource = tableView.dataSource as! BindingContextAsCheckableStringTableSource;
    
        var checkedItems = tableSource.checkedItems;
    
        if (tableSource.selectionMode == ListSelectionMode.multiple)
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
    
    open func setListboxSelection(_ tableView: UITableView, selectionItem: String, selection: JToken?)
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
    
    func listbox_ItemClicked(_ item: TableSourceItem)
    {
        logger.debug("Listbox item clicked");
    
        let tableView: UITableView = self.control as! UITableView;
        let tableSource = tableView.dataSource! as! BindingContextAsCheckableStringTableSource;
    
        if (tableSource.selectionMode == ListSelectionMode.none)
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
    
    func listbox_SelectionChanged(_ item: TableSourceItem)
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
    
        if ((!_selectionChangingProgramatically) && (tableSource.selectionMode != ListSelectionMode.none))
        {
            if let command = getCommand(CommandName.OnSelectionChange)
            {
                logger.debug("ListView selection change with command: \(command)");
    
                if (tableSource.selectionMode == ListSelectionMode.single)
                {
                    if let listItem = item as? BindingContextAsStringTableSourceItem
                    {
                        // The selection change command handler resolves its tokens relative to the item selected when in single select mode.
                        //
                        stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(listItem.bindingContext));
                    }
                }
                else if (tableSource.selectionMode == ListSelectionMode.multiple)
                {
                    // The selection change command handler resolves its tokens relative to the list context when in multiple select mode.
                    //
                    stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(self.bindingContext));
                }
            }
        }
    }
}
