//
//  iOSPickerWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSPickerWrapper");

public class BindingContextPickerModel : NSObject, UIPickerViewDataSource, UIPickerViewDelegate
{
    var _bindingContexts: [BindingContext]!;
    var _itemContent: String!;
    
    public override init()
    {
        super.init();
    }
    
    public func setContents(bindingContext: BindingContext, itemContent: String)
    {
        _bindingContexts = bindingContext.selectEach("$data");
        _itemContent = itemContent;
    }
    
    // UIPickerViewDataSource
    public func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int
    {
        logger.debug("Returning number of components: 1");
        return 1;
    }
    
    // UIPickerViewDataSource
    public func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        var rows = (_bindingContexts != nil) ? _bindingContexts.count : 0;
        logger.debug("Returning number of rows in component \(component): \(rows)");
        return rows;
    }
    
    // UIPickerViewDelegate
    public func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String!
    {
        var title = PropertyValue.expandAsString(_itemContent, bindingContext: _bindingContexts[row]);
        logger.debug("returning title for row \(row): \(title)");
        return title;
    }
    
    public func getValue(row: Int) -> JToken?
    {
        return _bindingContexts[row].select("$data").getValue();
    }
    
    public func getSelection(row: Int, selectionItem: String) -> JToken?
    {
        return _bindingContexts[row].select(selectionItem).getValue()?.deepClone();
    }
    
    public func getBindingContext(row: Int) -> BindingContext
    {
        return _bindingContexts[row];
    }
    
    // UIPickerViewDelegate
    public func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat
    {
        logger.debug("Returning row height of 40 for component: \(component)");
        return CGFloat(40.0);
    }

    // UIPickerViewDelegate
    public func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        // This fires whenever an item is selected in the picker view (meaning that the item has been
        // scrolled to and highlighted, not that the user as necessarily "chosen" the value in the sense
        // that we are interested in here).  So for that reason, this isn't really useful.  We instead
        // watch the "Done" button and grab the selection when the picker is dismissed.
    }
}

public class PickerTextField : UITextField
{
    // This gets rid of the blinking caret when "editing" (which in our case, means having the picker input view up).
    //
    public override func caretRectForPosition(position: UITextPosition) -> CGRect
    {
        return CGRect.nullRect;
    }
}

private var commands = [CommandName.OnSelectionChange.Attribute];

public class iOSPickerWrapper : iOSControlWrapper
{
    // On phones, we have a picker "input view" at the bottom of the screen when "editing", similar to the way the keyboard
    // pops up there for a regular text field.  This is modelled after:
    //
    //     http://www.gooorack.com/2013/07/18/xamarin-uipickerview-as-a-combobox/
    //
    // On tablets, it might be more appropriate to use a popover near the control to show the list, such as this:
    //
    //     https://github.com/xamarin/monotouch-samples/blob/master/MonoCatalog-MonoDevelop/PickerViewController.xib.cs
    //
    
    var _selectionChangingProgramatically = false;
    var _localSelection: JToken?;
    
    var _lastSelectedPosition = -1;
    
    var _picker: UIPickerView;
    var _textBox: PickerTextField!;
    
    var _model: BindingContextPickerModel;

    public init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating picker element");
        
        _picker = UIPickerView();
        
        _model = BindingContextPickerModel();
        _picker.dataSource = _model;
        _picker.delegate = _model;
        
        _picker.showsSelectionIndicator = true;

        _textBox = PickerTextField();
        _textBox.borderStyle = UITextBorderStyle.RoundedRect;
        
        super.init(parent: parent, bindingContext: bindingContext);

        self._control = _textBox;
        
        processElementDimensions(controlSpec, defaultWidth: 150, defaultHeight: 50);
        applyFrameworkElementDefaults(_textBox);
        
        var toolbar = UIToolbar();
        toolbar.barStyle = UIBarStyle.Black;
        toolbar.translucent = true;
        toolbar.sizeToFit();
        
        var doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: "doneButtonPressed:");
        toolbar.setItems([doneButton], animated: true);
        
        _textBox.inputView = _picker;
        _textBox.inputAccessoryView = toolbar;
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "items", commandAttributes: commands)
        {
            processCommands(bindingSpec, commands: commands);
            
            if let items = bindingSpec["items"]
            {
                var theItemContent = bindingSpec["itemContent"]?.asString() ?? "{$data}";
                
                processElementBoundValue(
                    "items",
                    attributeValue: items,
                    getValue: { () in self.getPickerContents(self._picker) },
                    setValue: { (value) in self.setPickerContents(self._picker, bindingContext: self.getValueBinding("items")!.bindingContext, itemContent: theItemContent) }
                );
            }
            
            if let selection = bindingSpec["selection"]
            {
                var theSelectionItem = bindingSpec["selectionItem"]?.asString() ?? "$data";
                
                processElementBoundValue(
                    "selection",
                    attributeValue: selection,
                    getValue: { () in self.getPickerSelection(self._picker, selectionItem: theSelectionItem) },
                    setValue: { (value) in self.setPickerSelection(self._picker, selectionItem: theSelectionItem, selection: value!) }
                );
            }
        }
    }
    
    func doneButtonPressed(sender: UIBarButtonItem)
    {
        if (_textBox.isFirstResponder())
        {
            var model = _picker.dataSource as! BindingContextPickerModel;

            var row = _picker.selectedRowInComponent(0);
            _textBox.text = model.pickerView(_picker, titleForRow: row, forComponent: 0);
            _textBox.resignFirstResponder();
            self.picker_ItemSelected(_picker, row: row);
        }
    }
    
    public func getPickerContents(picker: UIPickerView) -> JToken
    {
        fatalError("getPickerContents not implemented");
    }
    
    public func setPickerContents(picker: UIPickerView, bindingContext: BindingContext, itemContent: String)
    {
        logger.debug("Setting picker contents");
    
        _selectionChangingProgramatically = true;
        
        var model = picker.dataSource as! BindingContextPickerModel;
        model.setContents(bindingContext, itemContent: itemContent);
        
        if let selectionBinding = getValueBinding("selection")
        {
            selectionBinding.updateViewFromViewModel();
        }
        else if (_localSelection != nil)
        {
            // If there is not a "selection" value binding, then we use local selection state to restore the selection when
            // re-filling the list.
            //
            self.setPickerSelection(picker, selectionItem: "$data", selection: _localSelection!);
        }
        
        _selectionChangingProgramatically = false;
    }
    
    public func getPickerSelection(picker: UIPickerView, selectionItem: String) -> JToken
    {
        var model = picker.dataSource as! BindingContextPickerModel;
        
        if (picker.selectedRowInComponent(0) >= 0)
        {
            return model.getSelection(picker.selectedRowInComponent(0), selectionItem: selectionItem) ?? JValue(false);
        }
        return JValue(false); // This is a "null" selection
    }
    
    public func setPickerSelection(picker: UIPickerView, selectionItem: String, selection: JToken)
    {
        _selectionChangingProgramatically = true;

        var model = picker.dataSource as! BindingContextPickerModel;
    
        for (var i = 0; i < model.pickerView(picker, numberOfRowsInComponent: 0); i++)
        {
            if (JToken.deepEquals(selection, token2: model.getSelection(i, selectionItem: selectionItem)))
            {
                picker.selectedRowInComponent(0);
                _textBox.text = model.pickerView(picker, titleForRow: i, forComponent: 0);
                _lastSelectedPosition = i;
                picker.selectRow(i, inComponent: 0, animated: true);
                break;
            }
        }
    
        _selectionChangingProgramatically = false;
    }
    
    func picker_ItemSelected(picker: UIPickerView, row: Int)
    {
        logger.debug("Picker selection changed");
    
        if let selectionBinding = getValueBinding("selection")
        {
            updateValueBindingForAttribute("selection");
        }
        else if (!_selectionChangingProgramatically)
        {
            _localSelection = self.getPickerSelection(picker, selectionItem: "$data");
        }
        
        if ((!_selectionChangingProgramatically) && (row != _lastSelectedPosition))
        {
            _lastSelectedPosition = row;
            if let command = getCommand(CommandName.OnSelectionChange)
            {
                logger.debug("Picker item click with command: \(command)");
                
                // The item click command handler resolves its tokens relative to the item clicked (not the list view).
                //
                var model = picker.dataSource as! BindingContextPickerModel;
                stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(model.getBindingContext(row)));
            }
        }
    }
}
