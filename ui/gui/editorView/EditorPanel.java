/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package gui.editorView;

import entity.Model;
import gui.AbstractComponentPanel;
import gui.State;
import java.awt.GridLayout;
import java.io.File;

import java.util.ListIterator;
import java.util.Map;

import javax.swing.JFileChooser;

import solution.SolverTestSAT4J;

/**
 *
 * @author Skander
 */
public class EditorPanel extends AbstractComponentPanel {

    /**
     * Creates new form EditorPanel
     */
    public EditorPanel() {
        initComponents();
        jFileChooser1.setCurrentDirectory(new File(System.getProperties().getProperty("user.dir")));
    }

    private void applyRestrictions() {
        switch (getState()) {
            case EDIT_SINGLE :
                formulaTablePanel1.allowRemoval(false);
                break;
            case EDIT_MULTIPLE :
                formulaTablePanel1.allowRemoval(true);
                break;
            case SINGLE_RESULT :
                // impossible
                break;
            case FIRST_RESULT :
                // impossible
                break;
            case INTER_RESULT :
                // impossible
                break;
            case LAST_RESULT :
                // impossible
                break;
            default :
                System.out.println("Undefined action set for the state : " + getState());
        }
    }

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jFileChooser1 = new javax.swing.JFileChooser();
        jButtonTest = new javax.swing.JButton();
        jButtonImport = new javax.swing.JButton();
        jSplitPane1 = new javax.swing.JSplitPane();
        jPanel2 = new javax.swing.JPanel();
        jLabel1 = new javax.swing.JLabel();
        jButtonAddFormula = new javax.swing.JButton();
        jScrollPane1 = new javax.swing.JScrollPane();
        formulaTablePanel1 = new gui.editorView.FormulaTablePanel();
        palettePanel1 = new gui.editorView.PalettePanel(formulaTablePanel1);

        jButtonTest.setText("Tester");
        jButtonTest.addActionListener(new java.awt.event.ActionListener() {
            @Override
			public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonTestActionPerformed(evt);
            }
        });

        jButtonImport.setText("Importer");
        jButtonImport.addActionListener(new java.awt.event.ActionListener() {
            @Override
			public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonImportActionPerformed(evt);
            }
        });

        jLabel1.setText("Formules");

        jButtonAddFormula.setText("Ajouter");
        jButtonAddFormula.addActionListener(new java.awt.event.ActionListener() {
            @Override
			public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonAddFormulaActionPerformed(evt);
            }
        });

        jScrollPane1.setViewportView(formulaTablePanel1);

        javax.swing.GroupLayout jPanel2Layout = new javax.swing.GroupLayout(jPanel2);
        jPanel2.setLayout(jPanel2Layout);
        jPanel2Layout.setHorizontalGroup(
            jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel2Layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(jLabel1)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                .addComponent(jButtonAddFormula)
                .addContainerGap())
            .addComponent(jScrollPane1, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.DEFAULT_SIZE, 640, Short.MAX_VALUE)
        );
        jPanel2Layout.setVerticalGroup(
            jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel2Layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(jPanel2Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel1)
                    .addComponent(jButtonAddFormula))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 419, Short.MAX_VALUE))
        );

        jSplitPane1.setRightComponent(jPanel2);
        jSplitPane1.setLeftComponent(palettePanel1);

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                .addComponent(jButtonImport)
                .addGap(18, 18, 18)
                .addComponent(jButtonTest)
                .addContainerGap())
            .addComponent(jSplitPane1)
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addComponent(jSplitPane1)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jButtonTest)
                    .addComponent(jButtonImport))
                .addContainerGap())
        );
    }// </editor-fold>//GEN-END:initComponents

    private void jButtonAddFormulaActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonAddFormulaActionPerformed
        // TODO add your handling code here:
        switch(getState()) {
            case EDIT_SINGLE :
                setState(State.EDIT_MULTIPLE);
                formulaTablePanel1.addFormula();
                applyRestrictions();
                break;
            case EDIT_MULTIPLE :
                setState(State.EDIT_MULTIPLE);
                formulaTablePanel1.addFormula();
                applyRestrictions();
                break;
            case SINGLE_RESULT :
                // impossible
                break;
            case FIRST_RESULT :
                // impossible
                break;
            case INTER_RESULT :
                // impossible
                break;
            case LAST_RESULT :
                // impossible
                break;
            default :
                System.out.println("Undefined action set for the state : " + getState());
        }
    }//GEN-LAST:event_jButtonAddFormulaActionPerformed

    private State initResultsView() {
        /*
        Faire appel au solveur avec les fichiers générés par le traducteur
        calculer un model
        Si un model suivant existe
        alors passer a l'état FIRST_RESULT
        sinon passer à l'état SINGLE_RESULT
        */
        
        String bigAndFilePath = "bigAndFile-defaultname.txt"; //TODO se mettre d'accord sur un nom standard ou ajouter a Translator et BaseDeClause des méthode pour s'échange de objets File
        try {
            getFrame().getClause().saveToFile(bigAndFilePath); //TODO gérer les IOException
            getFrame().getTranslator().translate(bigAndFilePath); //TODO gérer les erreurs : return false ou IOException
        } catch (Exception e) {
            //TODO gérer proprement les exceptions
            e.printStackTrace();
        }
        //TODO delete the generated file "bigAndFile-defaultname.txt"
        //Add CurrentPath/dimacsFile
        String translatedFilePath = getFrame().getTranslator().getDimacsFilePath();
        Map<Integer, String> literalsMap = getFrame().getTranslator().getLiteralsMap();
        getFrame().setSolver(new SolverTestSAT4J(translatedFilePath, literalsMap));
        
        try {
            getFrame().getSolver().launch(); //TODO gérer les IOException
        } catch (Exception e) {
            //TODO gérer proprement les exceptions
            e.printStackTrace();
        }
        if(! getFrame().getSolver().isSatisfiable()) {
            System.out.println("Erreur : Clauses non satisfiable");
        }
         //Initialise l'iterator de ResultsPanel
            getFrame().updateResultsPanelIterator();
        
        // Si il y a au moins un model
        try {
            ListIterator<Model> iter = (ListIterator<Model>) getFrame().getSolver().getModelList().iterator();
            /**
             * Si il y a plus d'un model, alors passer à l'état FIRST_RESULT
             * sinon passer à l'état SINGLE_RESULT
             */
            if (iter.hasNext()) {
           //     iter.next();
                if (iter.hasNext()) {
                   //iter.previous();
                    return State.FIRST_RESULT;
                } else {
                    //iter.previous();
                    return State.SINGLE_RESULT;
                }
            } else {
                return State.SINGLE_RESULT;
            }
        } catch (Exception e) {
            //TODO gérer proprement les exceptions
            e.printStackTrace();
        }
        return getState();
    }

    private void jButtonTestActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonTestActionPerformed
        State state;
        switch(getState()) {
            case EDIT_SINGLE :
                state = initResultsView();
                if (state != getState()) {
                    setState(state);
                    getFrame().setViewToResults();
                }
                break;
            case EDIT_MULTIPLE :
                state = initResultsView();
                if (state != getState()) {
                    setState(state);
                    getFrame().setViewToResults();
                }
                break;
            case SINGLE_RESULT :
                // impossible
                break;
            case FIRST_RESULT :
                // impossible
                break;
            case INTER_RESULT :
                // impossible
                break;
            case LAST_RESULT :
                // impossible
                break;
            default :
                System.out.println("Undefined action set for the state : " + getState());
        }
    }//GEN-LAST:event_jButtonTestActionPerformed

    private void appelBaseDeClauseImport() {
        String path = "";
        jFileChooser1.setFileSelectionMode(JFileChooser.FILES_ONLY);
        jFileChooser1.showDialog(this, "Importer fichier");
        try {
            path = jFileChooser1.getSelectedFile().getPath();
        } catch (NullPointerException e) {
            //TODO handle the case where user doesn't select a file or cancel the operation.
            e.printStackTrace();
        }
        System.out.println(getFrame().getClause().getFormules());

        try {
            getFrame().getClause().uploadFile(path);
        } catch(Exception e) {
            System.out.println("Error : Failed to load the file : " + path);
            e.printStackTrace();
        }
        
        //Réinitialisation des sets et des formules
        formulaTablePanel1.removeAll();
        formulaTablePanel1.setLayout(new GridLayout(getFrame().getClause().getSets().size()
                + getFrame().getClause().getFormules().size(), 1));
        for(int i=0; i<getFrame().getClause().getSets().size(); i++) {
            formulaTablePanel1.add(new FormulaPanel(i, FormulaPanelType.SET, getFrame().getClause().getSets().get(i)));
        }
        for(int i=0; i<getFrame().getClause().getFormules().size(); i++) {
            formulaTablePanel1.add(new FormulaPanel(i, FormulaPanelType.FORMULA, getFrame().getClause().getFormules().get(i)));
        }
        getFrame().setNumberOfFormulas(getFrame().getClause().getSets().size() 
                + getFrame().getClause().getFormules().size());
        formulaTablePanel1.updateUI();
    }

    private void jButtonImportActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonImportActionPerformed
        switch (getState()) {
            case EDIT_SINGLE :
                setState(State.EDIT_SINGLE);
                appelBaseDeClauseImport();
                break;
            case EDIT_MULTIPLE :
                setState(State.EDIT_MULTIPLE);
                appelBaseDeClauseImport();
                break;
            case SINGLE_RESULT :
                // impossible
                break;
            case FIRST_RESULT :
                // impossible
                break;
            case INTER_RESULT :
                // impossible
                break;
            case LAST_RESULT :
                // impossible
                break;
            default :
                System.out.println("Undefined action set for the state : " + getState());
        }
    }//GEN-LAST:event_jButtonImportActionPerformed


    // Variables declaration - do not modify//GEN-BEGIN:variables
    private gui.editorView.FormulaTablePanel formulaTablePanel1;
    private javax.swing.JButton jButtonAddFormula;
    private javax.swing.JButton jButtonImport;
    private javax.swing.JButton jButtonTest;
    private javax.swing.JFileChooser jFileChooser1;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JPanel jPanel2;
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JSplitPane jSplitPane1;
    private gui.editorView.PalettePanel palettePanel1;
    // End of variables declaration//GEN-END:variables
}
