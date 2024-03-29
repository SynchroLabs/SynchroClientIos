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

open class BindingContextPickerModel : NSObject, UIPickerViewDataSource, UIPickerViewDelegate
{
    var _bindingContexts: [BindingContext]!;
    var _itemContent: String!;
    
    public override init()
    {
        super.init();
    }
    
    open func setContents(_ bindingContext: BindingContext, itemContent: String)
    {
        _bindingContexts = bindingContext.selectEach("$data");
        _itemContent = itemContent;
    }
    
    // UIPickerViewDataSource
    open func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        logger.debug("Returning number of components: 1");
        return 1;
    }
    
    // UIPickerViewDataSource
    open func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        let rows = (_bindingContexts != nil) ? _bindingContexts.count : 0;
        logger.debug("Returning number of rows in component \(component): \(rows)");
        return rows;
    }
    
    // UIPickerViewDelegate
    open func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        let title = PropertyValue.expandAsString(_itemContent, bindingContext: _bindingContexts[row]);
        logger.debug("returning title for row \(row): \(title)");
        return title;
    }
    
    open func getValue(_ row: Int) -> JToken?
    {
        return _bindingContexts[row].select("$data").getValue();
    }
    
    open func getSelection(_ row: Int, selectionItem: String) -> JToken?
    {
        return _bindingContexts[row].select(selectionItem).getValue()?.deepClone();
    }
    
    open func getBindingContext(_ row: Int) -> BindingContext
    {
        return _bindingContexts[row];
    }
    
    // UIPickerViewDelegate
    open func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat
    {
        logger.debug("Returning row height of 40 for component: \(component)");
        return CGFloat(40.0);
    }

    // UIPickerViewDelegate
    open func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        // This fires whenever an item is selected in the picker view (meaning that the item has been
        // scrolled to and highlighted, not that the user as necessarily "chosen" the value in the sense
        // that we are interested in here).  So for that reason, this isn't really useful.  We instead
        // watch the "Done" button and grab the selection when the picker is dismissed.
    }
}

open class PickerTextField : UITextField
{
    // This gets rid of the blinking caret when "editing" (which in our case, means having the picker input view up).
    //
    open override func caretRect(for position: UITextPosition) -> CGRect
    {
        return CGRect.null;
    }
}

private var commands = [CommandName.OnSelectionChange.Attribute];

open class iOSPickerWrapper : iOSControlWrapper
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

    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating picker element");
        
        _picker = UIPickerView();
        
        _model = BindingContextPickerModel();
        _picker.dataSource = _model;
        _picker.delegate = _model;
        
        _picker.showsSelectionIndicator = true;

        _textBox = PickerTextField();
        _textBox.borderStyle = UITextBorderStyle.roundedRect;
        
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);

        self._control = _textBox;
        
        processElementDimensions(controlSpec, defaultWidth: 100);
        
        applyFrameworkElementDefaults(_textBox);
        
        let toolbar = UIToolbar();
        toolbar.barStyle = UIBarStyle.black;
        toolbar.isTranslucent = true;
        toolbar.sizeToFit();
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(doneButtonPressed));
        toolbar.setItems([doneButton], animated: true);
        
        _textBox.inputView = _picker;
        _textBox.inputAccessoryView = toolbar;
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "items", commandAttributes: commands)
        {
            processCommands(bindingSpec, commands: commands);
            
            if let items = bindingSpec["items"]
            {
                let theItemContent = bindingSpec["itemContent"]?.asString() ?? "{$data}";
                
                processElementBoundValue(
                    "items",
                    attributeValue: items,
                    getValue: { () in self.getPickerContents(self._picker) },
                    setValue: { (value) in self.setPickerContents(self._picker, bindingContext: self.getValueBinding("items")!.bindingContext, itemContent: theItemContent) }
                );
            }
            
            if let selection = bindingSpec["selection"]
            {
                let theSelectionItem = bindingSpec["selectionItem"]?.asString() ?? "$data";
                
                processElementBoundValue(
                    "selection",
                    attributeValue: selection,
                    getValue: { () in self.getPickerSelection(self._picker, selectionItem: theSelectionItem) },
                    setValue: { (value) in self.setPickerSelection(self._picker, selectionItem: theSelectionItem, selection: value!) }
                );
            }
        }
    }
    
    func doneButtonPressed(_ sender: UIBarButtonItem)
    {
        if (_textBox.isFirstResponder)
        {
            let model = _picker.dataSource as! BindingContextPickerModel;

            let row = _picker.selectedRow(inComponent: 0);
            _textBox.text = model.pickerView(_picker, titleForRow: row, forComponent: 0);
            _textBox.resignFirstResponder();
            self.picker_ItemSelected(_picker, row: row);
        }
    }
    
    open func getPickerContents(_ picker: UIPickerView) -> JToken
    {
        fatalError("getPickerContents not implemented");
    }
    
    open func setPickerContents(_ picker: UIPickerView, bindingContext: BindingContext, itemContent: String)
    {
        logger.debug("Setting picker contents");
    
        _selectionChangingProgramatically = true;
        
        let model = picker.dataSource as! BindingContextPickerModel;
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
    
    open func getPickerSelection(_ picker: UIPickerView, selectionItem: String) -> JToken
    {
        let model = picker.dataSource as! BindingContextPickerModel;
        
        if (picker.selectedRow(inComponent: 0) >= 0)
        {
            return model.getSelection(picker.selectedRow(inComponent: 0), selectionItem: selectionItem) ?? JValue(false);
        }
        return JValue(false); // This is a "null" selection
    }
    
    open func setPickerSelection(_ picker: UIPickerView, selectionItem: String, selection: JToken)
    {
        _selectionChangingProgramatically = true;

        let model = picker.dataSource as! BindingContextPickerModel;
    
        for i in 0 ..< model.pickerView(picker, numberOfRowsInComponent: 0)
        {
            if (JToken.deepEquals(selection, token2: model.getSelection(i, selectionItem: selectionItem)))
            {
                picker.selectedRow(inComponent: 0);
                _textBox.text = model.pickerView(picker, titleForRow: i, forComponent: 0);
                _lastSelectedPosition = i;
                picker.selectRow(i, inComponent: 0, animated: true);
                break;
            }
        }
    
        _selectionChangingProgramatically = false;
    }
    
    func picker_ItemSelected(_ picker: UIPickerView, row: Int)
    {
        logger.debug("Picker selection changed");
    
        if (getValueBinding("selection") != nil)
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
                let model = picker.dataSource as! BindingContextPickerModel;
                stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(model.getBindingContext(row)));
            }
        }
    }
}
