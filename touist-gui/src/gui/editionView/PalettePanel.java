/*
 *
 * Project TouIST, 2015. Easily formalize and solve real-world sized problems
 * using propositional logic and linear theory of reals with a nice GUI.
 *
 * https://github.com/olzd/touist
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the GNU Lesser General Public License
 * (LGPL) version 2.1 which accompanies this distribution, and is available at
 * http://www.gnu.org/licenses/lgpl-2.1.html
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * Contributors:
 *     Alexis Comte, Abdelwahab Heba, Olivier Lezaud,
 *     Skander Ben Slimane, Maël Valais
 *
 */

package gui.editionView;

import gui.AbstractComponentPanel;
import gui.Lang;
import gui.editionView.editor.Editor;
import java.awt.Component;

import java.util.ArrayList;

import javax.swing.BoxLayout;

/**
 *
 * @author Skander
 */
public class PalettePanel extends AbstractComponentPanel {

    @Override
    public void updateLanguage() {
        jLabel1.setText(getFrame().getLang().getWord(Lang.PALETTE_TEXT));
        if(section1!=null) section1.setText(getFrame().getLang().getWord("PaletteSectionPanel.FormulasSection1"));
        if(section2!=null) section2.setText(getFrame().getLang().getWord("PaletteSectionPanel.FormulasSection2"));
        if(section3!=null) section3.setText(getFrame().getLang().getWord("PaletteSectionPanel.SetsSection1"));
    }

    public static enum PaletteType {FORMULA, SET};
    
    private Editor editorTextArea;
    
    public PalettePanel() {
        initComponents();
    }
    
    /**
     * Creates new form PalettePanel
     * @param editorTextArea
     */
    public PalettePanel(Editor editorTextArea) {
        initComponents();
        this.editorTextArea = editorTextArea;
    }

    public void setEditorTextArea(Editor editorTextArea) {
        this.editorTextArea = editorTextArea;
    }
    
    private PaletteSectionPanel section1;
    private PaletteSectionPanel section2;
    private PaletteSectionPanel section3;
    
    public void initPaletteContent(PaletteType type) {
        if (type == PaletteType.FORMULA) {
            section1 = new PaletteSectionPanel("");
            section2 = new PaletteSectionPanel("");

            ArrayList<Integer> snippetsAnd = new ArrayList<Integer>(){{add(0);add(1);add(7);add(8);}};
            ArrayList<Integer> snippetsOr = new ArrayList<Integer>(){{add(0);add(1);add(6);add(7);}};
            ArrayList<Integer> snippetsNot = new ArrayList<Integer>(){{add(4);add(5);}};
            ArrayList<Integer> snippetsIf = new ArrayList<Integer>(){{add(3);add(4);add(14);add(15);add(25);add(26);}};
            ArrayList<Integer> snippetsBigand = new ArrayList<Integer>(){{add(7);add(8);add(13);add(14);}};
            
            section1.addInsertButton(new InsertionButton(editorTextArea, "$a and $b", snippetsAnd, "and"));
            section1.addInsertButton(new InsertionButton(editorTextArea, "$a or $b", snippetsOr, "or"));
            section1.addInsertButton(new InsertionButton(editorTextArea, "not $a", snippetsNot, "not"));
            section2.addInsertButton(new InsertionButton(editorTextArea, "if $a \nthen \n\t$b \nelse \n\t$c\n", snippetsIf, "if then else","if\\,\\$a \\\\ then\\\\\\quad\\$b \\\\ else\\\\\\quad\\$c"));
            section1.addInsertButton(new InsertionButton(editorTextArea, "bigand $i in $a: \n\tA($i) and B($i) \nend", snippetsBigand,"bigand"));

            sectionsContainerPanel.setLayout(new BoxLayout(sectionsContainerPanel, BoxLayout.Y_AXIS));
            sectionsContainerPanel.add(section1);
            sectionsContainerPanel.add(section2);
        } else if (type == PaletteType.SET) {
            section3 = new PaletteSectionPanel("KzdaljahdjlAJHJAZDHAZH zadh azmohozudhazoudhazoduhaou");

            ArrayList<Integer> snippetsSet = new ArrayList<Integer>(){{add(0);add(1);}};
            
            section3.addInsertButton(new InsertionButton(editorTextArea, "$a = [a,b,c]", snippetsSet, ""));
            section3.addInsertButton(new InsertionButton(editorTextArea, "$b = [a,d,e,f]", snippetsSet, ""));

            sectionsContainerPanel.setLayout(new BoxLayout(sectionsContainerPanel, BoxLayout.Y_AXIS));
            sectionsContainerPanel.add(section3);
        }
    }
    
    public int getRecommendWidth() {
        int width = 0;
        for (Component section : sectionsContainerPanel.getComponents()) {
            if (section instanceof PaletteSectionPanel) {
                for (InsertionButton button : ((PaletteSectionPanel)section).getButtons()) {
                    width = Math.max(width, button.getIcon().getIconWidth() + 40);
                }
            }
        }
        return width;
    }

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jLabel1 = new javax.swing.JLabel();
        sectionsContainerPanel = new javax.swing.JPanel();

        jLabel1.setFont(new java.awt.Font("Tahoma", 1, 11)); // NOI18N
        jLabel1.setText("Insert");

        sectionsContainerPanel.setLayout(new javax.swing.BoxLayout(sectionsContainerPanel, javax.swing.BoxLayout.LINE_AXIS));

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(sectionsContainerPanel, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(jLabel1)
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addComponent(jLabel1)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(sectionsContainerPanel, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );
    }// </editor-fold>//GEN-END:initComponents


    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JLabel jLabel1;
    private javax.swing.JPanel sectionsContainerPanel;
    // End of variables declaration//GEN-END:variables
}
