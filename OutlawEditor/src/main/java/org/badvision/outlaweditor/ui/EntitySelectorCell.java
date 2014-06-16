/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package org.badvision.outlaweditor.ui;

import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import javafx.scene.control.ListCell;
import javafx.scene.control.TextField;
import javafx.scene.control.cell.ComboBoxListCell;
import org.badvision.outlaweditor.data.PropertyHelper;
import org.badvision.outlaweditor.ui.impl.ApplicationUIControllerImpl;

/**
 *
 * @author blurry
 */
public abstract class EntitySelectorCell<T> extends ComboBoxListCell<T> {
    static Map<TextField, Object> lastSelected = new HashMap<>();
    TextField nameField;

    public EntitySelectorCell(TextField tileNameField) {
        super.setPrefWidth(125);
        nameField = tileNameField;
    }

    @Override
    public void updateSelected(boolean sel) {
        if (sel) {
            Object o = lastSelected.get(nameField);
            if (o != null && !o.equals(getItem())) {
                ((ListCell) o).updateSelected(false);
            }
            textProperty().unbind();
            textProperty().bind(nameField.textProperty());
            lastSelected.put(nameField, this);
        } else {
            updateItem(getItem(), false);
        }
    }

    @Override
    public void updateItem(T item, boolean empty) {
        textProperty().unbind();
        super.updateItem(item, empty);
        if (item != null && !(item instanceof String)) {
            try {
                textProperty().bind(PropertyHelper.stringProp(item, "name"));
            } catch (NoSuchMethodException ex) {
                Logger.getLogger(ApplicationUIControllerImpl.class.getName()).log(Level.SEVERE, null, ex);
            }
            finishUpdate(item);
        } else {
            setText(null);
        }
    }

    public void finishUpdate(T item) {
    }
    
}