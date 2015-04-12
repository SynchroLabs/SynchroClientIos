//
//  iOSListViewWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSListViewWrapper");

public class BindingContextTableViewCell : UITableViewCell
{
    var _controlWrapper: iOSControlWrapper?;
    
    public var controlWrapper: iOSControlWrapper?
    {
        get { return _controlWrapper; }
        set(value)
        {
            if (_controlWrapper != value)
            {
                if (_controlWrapper != nil)
                {
                    // Remove any control currently set into this cell...
                    //
                    _controlWrapper!.control!.removeFromSuperview();
                }
                _controlWrapper = value;
                if (_controlWrapper != nil)
                {
                    if (_controlWrapper!.control!.superview != nil)
                    {
                        // If the control we're setting in this cell is still a child of something (presumably
                        // the cell to which it was previously assigned), we need to remove it from that parent
                        // before we assign it as our child (otherwise there are cases where a cell will end up
                        // with either zero or more than one set of controls, depending on the iOS version).
                        //
                        _controlWrapper!.control!.removeFromSuperview();
                    }
                    self.addSubview(_controlWrapper!.control!);
                }
            }
        }
    }
    
    public init(cellIdentifier: String)
    {
        super.init(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier)
    }

    required public init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func updateControlWidth(wrapper: iOSControlWrapper, cellWidth: CGFloat)
    {
        // If this control is "fill" width and the width provided is different than the current width, set
        // the new width and layout any subviews.
        //
        if (wrapper.frameProperties.widthSpec == SizeSpec.FillParent)
        {
            if (wrapper.control!.frame.width != cellWidth)
            {
                var cellBounds = wrapper.control!.frame;
                cellBounds.width = cellWidth;
                wrapper.control!.frame = cellBounds;
                wrapper.control!.layoutSubviews();
            }
        }
    }
    
    public override func layoutSubviews()
    {
        BindingContextTableViewCell.updateControlWidth(_controlWrapper!, cellWidth: self.frame.width);
        super.layoutSubviews();
    }
}

private var _cellIdentifier = "ListViewCell";

public class BindingContextTableSourceItem : TableSourceItem
{
    public var cellIdentifier: String { get { return _cellIdentifier; } }
    
    var _parentControlWrapper: iOSControlWrapper;
    var _contentControlWrapper: iOSControlWrapper;
    var _itemTemplate: JObject;
    
    var _bindingContext: BindingContext;
    public var bindingContext: BindingContext { get { return _bindingContext; } }
    
    public init(parentControl: iOSControlWrapper, itemTemplate: JObject, bindingContext: BindingContext)
    {
        _parentControlWrapper = parentControl;
        _itemTemplate = itemTemplate;
        _bindingContext = bindingContext;
        
        // Creating the content control here subverts the whole idea of recycling cells (we are technically
        // recycling the cells themselves, but we are maintaining the contents of the cells, a bunch of bound
        // controls, which is kind of against the spirit of supporting large lists without chewing up lots of
        // resources).
        //
        // What we should do is create the bound (in the Synchro sense) controls when this item is bound
        // to a cell.  Since we are going to be asked for the height of the cell later, and since that can
        // change once we bind the controls to a cell and the cell lays them out, we need to keep a reference
        // to the controls around (so we can see how tall they are at any time).
        //
        // But in order to really "recycle" the cells, we should remove that reference when this item becomes
        // "unbound" from the cell to which it is bound (at which point we, coincidentally, don't need to know
        // the height anymore).  This would entail doing an Unregister() on the content control wrapper, then
        // nulling out the reference to it.  The probelm is that we don't really get an unbinding notification,
        // and the only way to get that is to have the BindingContentTableViewCell keep track of what is bound
        // to it, such that when something else gets bound to it, it can notify the thing that it is going to
        // unbind.  That's an exercise for later.
        //
        // If the row height was the same for all items (perhaps specified in a rowHeight attribute, or if we
        // know somehow that the container control is a fixed height for all rows), then we could do this a much
        // more optimal way (we could create/assign the content control on BindCell, hand it to the cell, keep
        // no reference, and let the cell Unregister it directly when it was done with it).
        //
        _contentControlWrapper = iOSControlWrapper.createControl(_parentControlWrapper, bindingContext: _bindingContext, controlSpec: _itemTemplate)!;
    }
    
    public func createCell(tableView: UITableView) -> UITableViewCell
    {
        return BindingContextTableViewCell(cellIdentifier: cellIdentifier);
    }
    
    // Note that it is not uncommon to get a request to bind this item to a cell to which it has already been
    // most recently bound.  Check for and handle this case as appropriate.
    //
    public func bindCell(tableView: UITableView, cell: UITableViewCell)
    {
        var tableViewCell = cell as! BindingContextTableViewCell;
    
        // Now that we have the actual cell width, we're going to let the content control have a chance to set
        // its width and layout its children (assuming it's fill width and the width provided is different from
        // any current width).
        //
        BindingContextTableViewCell.updateControlWidth(_contentControlWrapper, cellWidth: cell.frame.width);
        
        tableViewCell.controlWrapper = _contentControlWrapper;
    }
    
    public func getHeightForRow(tableView: UITableView) -> CGFloat
    {
        // If the cell contents is set to fill width ("*") and wrap height, then we have to set the actual width
        // before we can compute the height, which we need here in order to avoid returning a zero (which causes
        // some redraw bugginess).
        //
        BindingContextTableViewCell.updateControlWidth(_contentControlWrapper, cellWidth: tableView.frame.width);
        
        // logger.info("Returning row height of: \(_contentControlWrapper.control.frame.height)");
        return _contentControlWrapper.control!.frame.height;
    }
    
    public func setCheckedState(tableView: UITableView, cell: UITableViewCell, isChecked: Bool) -> Bool
    {
        return false;
    }
}

public class CheckableBindingContextTableSource : CheckableTableSource
{
    var _parentControl: iOSControlWrapper;
    var _itemTemplate: JObject;
    
    public init(parentControl:iOSControlWrapper, itemTemplate: JObject, selectionMode: ListSelectionMode, onSelectionChanged: OnSelectionChanged, onItemClicked: OnItemClicked)
    {
        _parentControl = parentControl;
        _itemTemplate = itemTemplate;
        super.init(selectionMode: selectionMode, onSelectionChanged: onSelectionChanged, onItemClicked: onItemClicked);
    }
    
    public func setContents(bindingContext: BindingContext, itemSelector: String)
    {
        _tableItems.removeAll();
        for itemBindingContext in bindingContext.selectEach(itemSelector)
        {
            var item = BindingContextTableSourceItem(parentControl: _parentControl, itemTemplate: _itemTemplate, bindingContext: itemBindingContext);
            _tableItems.append(CheckableTableSourceItem(tableSourceItem: item, indexPath: NSIndexPath(forRow: _tableItems.count, inSection: 0)));
        }
    }
    
    public func addItem(bindingContext: BindingContext, isChecked: Bool = false)
    {
        var item = BindingContextTableSourceItem(parentControl: _parentControl, itemTemplate: _itemTemplate, bindingContext: bindingContext);
        _tableItems.append(CheckableTableSourceItem(tableSourceItem: item, indexPath: NSIndexPath(forRow: _tableItems.count, inSection: 0)));
    }
}

public class TableContainerView : UIView
{
    var _tableView: UITableView;
    var _controlWrapper: iOSControlWrapper;
    
    public init(tableView: UITableView, controlWrapper: iOSControlWrapper)
    {
    
        _tableView = tableView;
        _controlWrapper = controlWrapper;
        
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0));
    
        // For explicit (static) child dimensions - size parent UIView to fit...
        //
        var panelSize = self.frame.size;
        var margin = _controlWrapper.margin;
        
        if (_controlWrapper.frameProperties.widthSpec == SizeSpec.Explicit)
        {
            panelSize.width = _controlWrapper.control!.frame.width + margin.left + margin.right;
        }
        if (_controlWrapper.frameProperties.heightSpec == SizeSpec.Explicit)
        {
            panelSize.height = _controlWrapper.control!.frame.height + margin.top + margin.bottom;
        }
        if ((panelSize.width != self.frame.size.width) || (panelSize.height != self.frame.height))
        {
            var panelFrame = self.frame;
            panelFrame.size = panelSize;
            self.frame = panelFrame;
        }
        
        super.addSubview(_controlWrapper.control!);
        self.layoutSubviews();
    }

    required public init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateSize()
    {
        fatalError("This method must be overridden by the subclass");
    }
    
    public override func layoutSubviews()
    {
        // logger.info("LayoutSubviews");
        
        var panelSize = self.frame.size;
    
        var childView = _controlWrapper.control!;
        if (childView.hidden)
        {
            panelSize.height = 0;
        }
        else
        {
            var childFrame = childView.frame;
            var margin = _controlWrapper.margin;
    
            if (_controlWrapper.frameProperties.widthSpec == SizeSpec.WrapContent)
            {
                // Panel width will size to content
                //
                childFrame.x = margin.left;
                panelSize.width = childFrame.x + childFrame.width + margin.right;
            }
            else
            {
                // Panel width is explicit, so align content using the content horizontal alignment (along with margin)
                //
                childFrame.x = margin.left;
    
                if (_controlWrapper.frameProperties.widthSpec == SizeSpec.FillParent)
                {
                    // Child will fill parent (less margins)
                    //
                    childFrame.width = panelSize.width - (margin.left + margin.right);
                }
                else
                {
                    // Align child in parent
                    //
                    if (_controlWrapper.horizontalAlignment == HorizontalAlignment.Center)
                    {
                        // Ignoring margins on center for now.
                        childFrame.x = (panelSize.width - childFrame.width) / 2;
                    }
                    else if (_controlWrapper.horizontalAlignment == HorizontalAlignment.Right)
                    {
                        childFrame.x = (panelSize.width - childFrame.width - margin.right);
                    }
                }
            }
    
            if (_controlWrapper.frameProperties.heightSpec == SizeSpec.WrapContent)
            {
                // Panel height will size to content
                //
                childFrame.y = margin.top;
                panelSize.height = childFrame.y + childFrame.height + margin.bottom;
            }
            else if (_controlWrapper.frameProperties.heightSpec == SizeSpec.Explicit)
            {
                // Panel height is explicit, so align content using the content vertical alignment (along with margin)
                //
                childFrame.y = margin.top;
    
                if (_controlWrapper.frameProperties.heightSpec == SizeSpec.FillParent)
                {
                    // Child will fill parent (less margin)
                    //
                    childFrame.height = panelSize.height - (margin.top + margin.bottom);
                }
                else
                {
                    // Align child in parent
                    //
                    if (_controlWrapper.verticalAlignment == VerticalAlignment.Center)
                    {
                        // Ignoring margins on center for now.
                        childFrame.y = (panelSize.height - childFrame.height) / 2;
                    }
                    else if (_controlWrapper.verticalAlignment == VerticalAlignment.Bottom)
                    {
                        childFrame.y = (panelSize.height - childFrame.height - margin.bottom);
                    }
                }
            }
    
            // Update the content position
            //
            childView.frame = childFrame;
            // logger.info("Child frame: \(childView.frame)");
        }
    
        // See if the container panel changed size
        //
        if ((self.frame.width != panelSize.width) || (self.frame.height != panelSize.height))
        {
            // Resize the container panel...
            //
            var panelFrame = self.frame;
            panelFrame.size = panelSize;
            self.frame = panelFrame;
            // logger.info("Frame size chaged to: \(self.frame)");
        
            self.updateSize();
        }
        
        super.layoutSubviews();
    }
}

public class TableHeaderView : TableContainerView
{
    public override init(tableView: UITableView, controlWrapper: iOSControlWrapper)
    {
        super.init(tableView: tableView, controlWrapper: controlWrapper);
    }

    required public init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func updateSize()
    {
        // Apparently, The UITableView doesn't really expect its header/footer to change in size after
        // it is set.  Because ours can (due to layout changes based on binding), we have to poke the
        // table view by resetting the header/footer view, which seems get it to recognize the new size.
        //
        // Normally, when a child control changes size, it just lets its superview know that it needs to
        // update its layout, but the table view apparently doesn't work that way (for header/footer).
        //
        _tableView.tableHeaderView = self;
    }
}

public class TableFooterView : TableContainerView
{
    public override init(tableView: UITableView, controlWrapper: iOSControlWrapper)
    {
        super.init(tableView: tableView, controlWrapper: controlWrapper);
    }

    required public init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func updateSize()
    {
        // See comment in TableHeaderView:UpdateSize() above...
        //
        _tableView.tableFooterView = self;
    }
}

private var commands = [CommandName.OnItemClick.Attribute, CommandName.OnSelectionChange.Attribute];

public class iOSListViewWrapper : iOSControlWrapper
{
    var _selectionChangingProgramatically = false;
    var _localSelection: JToken?;
    var _dataSource: CheckableBindingContextTableSource!;

    public init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating listview element");
        
        super.init(parent: parent, bindingContext: bindingContext);
        
        var table = UITableView();
        self._control = table;
        
        // This is better performance, but only works if all the rows are the same height and you know the height ahead of time...
        //
        // table.RowHeight = 100;
        
        // The "new style" reuse model doesn't seem to work with custom table cell implementations
        //
        // table.RegisterClassForCellReuse(typeof(TableCell), TableCell.CellIdentifier);
        
        var selectionMode = toListSelectionMode(controlSpec["select"]);
        
        _dataSource = CheckableBindingContextTableSource(parentControl: self, itemTemplate: controlSpec["itemTemplate"] as! JObject, selectionMode: selectionMode, onSelectionChanged: listview_SelectionChanged, onItemClicked: listview_ItemClicked);
        table.dataSource = _dataSource;
        table.delegate = _dataSource;
        
        processElementDimensions(controlSpec, defaultWidth: 320, defaultHeight: 200);
        applyFrameworkElementDefaults(table);
        
        if (controlSpec["header"] != nil)
        {
            self.createControls(controlList: JArray([controlSpec["header"]!.deepClone()]), onCreateControl: { (childControlSpec, childControlWrapper) in
                table.tableHeaderView = TableHeaderView(tableView: table, controlWrapper: childControlWrapper);
            });
        }
        
        if (controlSpec["footer"] != nil)
        {
            self.createControls(controlList: JArray([controlSpec["footer"]!.deepClone()]), onCreateControl: { (childControlSpec, childControlWrapper) in
                table.tableFooterView = TableFooterView(tableView: table, controlWrapper: childControlWrapper);
            });
        }
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "items", commandAttributes: commands)
        {
            processCommands(bindingSpec, commands: commands);
            
            if (bindingSpec["items"] != nil)
            {
                processElementBoundValue(
                    "items",
                    attributeValue: bindingSpec["items"],
                    getValue: { () in self.getListViewContents(table) },
                    setValue: { (value) in self.setListViewContents(table, bindingContext: self.getValueBinding("items")!.bindingContext) });
            }
            
            if (bindingSpec["selection"] != nil)
            {
                var selectionItem = bindingSpec["selectionItem"]?.asString() ?? "$data";
                
                processElementBoundValue(
                    "selection",
                    attributeValue: bindingSpec["selection"],
                    getValue: { () in self.getListViewSelection(table, selectionItem: selectionItem) },
                    setValue: { (value) in self.setListViewSelection(table, selectionItem: selectionItem, selection: value) });
            }
        }
    }
    
    public func getListViewContents(tableView: UITableView) -> JToken
    {
        fatalError("getListViewContents not implemented");
    }
    
    public func setListViewContents(tableView: UITableView, bindingContext: BindingContext)
    {
        logger.debug("Setting listview contents");
    
        _selectionChangingProgramatically = true;
    
        var tableSource = tableView.dataSource! as! CheckableBindingContextTableSource;
    
        var oldCount = tableSource.allItems.count;
        tableSource.setContents(bindingContext, itemSelector: "$data");
        var newCount = tableSource.allItems.count;
        
        var reloadRows = [NSIndexPath]();
        var insertRows = [NSIndexPath]();
        var deleteRows = [NSIndexPath]();
        
        var maxCount = max(newCount, oldCount);
        for (var i = 0; i < maxCount; i++)
        {
            var row = NSIndexPath(forRow: i, inSection: 0);
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
    
        // Setting this to false, then back to true below, disables all row-motion animations, which
        // also eliminates to need for the footer gymnastics we used to do below, which in turn allows
        // the list items to stay in place as new items are added to the bottom and the footer is moved
        // down.  The row motion animations were kind of nice, but were causing way too many problems
        // to be worth their while.
        //
        UIView.setAnimationsEnabled(false);
        
        // We remove the footer temporarily, otherwise we experience a really bad animation effect
        // during the row animations below (the rows expand/contract very quickly, while the footer
        // slowly floats to its new location).  Looks terrible, especially when filling empty list.
        //
        /*
        UIView footer = tableView.TableFooterView;
        if (footer != nil)
        {
            // Note: Setting TableFooterView to null when it's already null causes a couple of very
            //       ugly issues (including a malloc error for writing to space that's already been
            //       freed, and an animation error on EndUpdates complaining about the number of
            //       rows after modification not being correct, even though they are).  So we check
            //       to make sure it's non-null before we clear it.  This is probably Xamarin.
            //
            tableView.tableFooterView = nil;
        }
        */
    
        // Note: The UITableViewRowAnimation specified variously below control the animation of
        //       the reveal of the row itself, and are not related to the other area of row animation,
        //       where rows themselves move around to reinforce insertion/deletion of rows.
        //
        tableView.beginUpdates();
        if (reloadRows.count > 0)
        {
            tableView.reloadRowsAtIndexPaths(reloadRows, withRowAnimation: UITableViewRowAnimation.None);
        }
        if (insertRows.count > 0)
        {
            tableView.insertRowsAtIndexPaths(insertRows, withRowAnimation: UITableViewRowAnimation.None);
        }
        if (deleteRows.count > 0)
        {
            tableView.deleteRowsAtIndexPaths(deleteRows, withRowAnimation: UITableViewRowAnimation.None);
        }
        tableView.endUpdates();
        
        UIView.setAnimationsEnabled(true);
        
        /*
        if (footer != nil)
        {
            tableView.tableFooterView = footer;
        }
        */
        
        if let selectionBinding = getValueBinding("selection")
        {
            selectionBinding.updateViewFromViewModel();
        }
        else if (_localSelection != nil)
        {
            // If there is not a "selection" value binding, then we use local selection state to restore the selection when
            // re-filling the list.
            //
            self.setListViewSelection(tableView, selectionItem: "$data", selection: _localSelection!);
        }
        
        _selectionChangingProgramatically = false;
    }
    
    public func getListViewSelection(tableView: UITableView, selectionItem: String) -> JToken
    {
        var tableSource = tableView.dataSource! as! CheckableBindingContextTableSource;
        
        var checkedItems = tableSource.checkedItems;
        
        if (tableSource.selectionMode == ListSelectionMode.Multiple)
        {
            var array = JArray();
            for item in checkedItems
            {
                if let theItem = item.tableSourceItem as? BindingContextTableSourceItem
                {
                    array.append(theItem.bindingContext.select(selectionItem).getValue()?.deepClone() ?? JValue());
                }
            }
            return array;
        }
        else
        {
            if (checkedItems.count > 0)
            {
                if let theItem = checkedItems[0].tableSourceItem as? BindingContextTableSourceItem
                {
                    // We need to clone the item so we don't destroy the original link to the item in the list (since the
                    // item we're getting in SelectedItem is the list item and we're putting it into the selection binding).
                    //
                    return theItem.bindingContext.select(selectionItem).getValue()?.deepClone() ?? JValue();
                }

            }
            return JValue(false); // This is a "null" selection
        }
    }
    
    // This gets triggered when selection changes come in from the server (including when the selection is initially set),
    // and it also gets triggered when the list itself changes (including when the list contents are intially set).  So
    // in the initial list/selection set case, this gets called twice.  On subsequent updates it's possible that this will
    // be triggered by either a list change or a selection change from the server, or both.  There is no easy way currerntly
    // to detect the "both" case (without exposing a lot more information here).  We're going to go ahead and live with the
    // multiple calls.  It shouldn't hurt anything (they should produce the same result), it's just slightly inefficient.
    //
    public func setListViewSelection(tableView: UITableView, selectionItem: String, selection: JToken?)
    {
        _selectionChangingProgramatically = true;
        
        var tableSource = tableView.dataSource! as! CheckableBindingContextTableSource;
        
        // Go through all values and check as appropriate
        //
        for checkableItem in tableSource.allItems
        {
            var isChecked = false;
            var bindingItem = checkableItem.tableSourceItem as! BindingContextTableSourceItem;
            var boundValue = bindingItem.bindingContext.select(selectionItem).getValue();
            
            if let array = selection as? JArray
            {
                for item in array
                {
                    if (JToken.deepEquals(item, token2: boundValue))
                    {
                        isChecked = true;
                        break;
                    }
                }
            }
            else
            {
                if (JToken.deepEquals(selection, token2: boundValue))
                {
                    isChecked = true;
                }
            }
            
            checkableItem.setChecked(tableView, isChecked: isChecked);
        }
        
        _selectionChangingProgramatically = false;
    }
    
    func listview_ItemClicked(itemClicked: TableSourceItem)
    {
        logger.debug("Listview item clicked: \(itemClicked)");
    
        var tableView: UITableView = self.control as! UITableView;
        var tableSource = tableView.dataSource! as! CheckableBindingContextTableSource;
        
        if (tableSource.selectionMode == ListSelectionMode.None)
        {
            if let listItem = itemClicked as? BindingContextTableSourceItem
            {
                if let command = getCommand(CommandName.OnItemClick)
                {
                    logger.debug("ListView item click with command: \(command)");
                    
                    // The item click command handler resolves its tokens relative to the item clicked.
                    //
                    stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(listItem.bindingContext));
                }
            }
        }
    }
    
    func listview_SelectionChanged(itemClicked: TableSourceItem)
    {
        logger.debug("Listview selection changed");
    
        var tableView: UITableView = self.control as! UITableView;
        var tableSource = tableView.dataSource! as! CheckableBindingContextTableSource;
        
        if let selectionBinding = getValueBinding("selection")
        {
            updateValueBindingForAttribute("selection");
        }
        else if (!_selectionChangingProgramatically)
        {
            _localSelection = self.getListViewSelection(tableView, selectionItem: "$data");
        }
        
        if ((!_selectionChangingProgramatically) && (tableSource.selectionMode != ListSelectionMode.None))
        {
            if let command = getCommand(CommandName.OnSelectionChange)
            {
                logger.debug("ListView selection change with command: \(command)");
                
                if (tableSource.selectionMode == ListSelectionMode.Single)
                {
                    if let item = itemClicked as? BindingContextTableSourceItem
                    {
                        // The selection change command handler resolves its tokens relative to the item selected when in single select mode.
                        //
                        stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(item.bindingContext));
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

