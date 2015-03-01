/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package gui.resultsView;

import gui.AbstractComponentPanel;
import gui.State;
import form.Model;

/**
 *
 * @author Skander
 */
public class ResultsPanel extends AbstractComponentPanel {

    private int currentModelIndex = 0;
    
    /**
     * Creates new form ResultsPanel
     */
    public ResultsPanel() {
        initComponents();
    }

    /**
     * Enable the next and previous buttons depending on the frame state.
     */
    public void applyRestrictions() {
        switch(getState()) {
            case EDIT_SINGLE : 
                // impossible
                break;
            case EDIT_MULTIPLE :
                // impossible
                break;
            case SINGLE_RESULT :
                jButtonNext.setEnabled(false);
                jButtonPrevious.setEnabled(false);
                break;
            case FIRST_RESULT : 
                jButtonNext.setEnabled(true);
                jButtonPrevious.setEnabled(false);
                break;
            case INTER_RESULT : 
                jButtonNext.setEnabled(true);
                jButtonPrevious.setEnabled(true);
                break;
            case LAST_RESULT :
                jButtonNext.setEnabled(false);
                jButtonPrevious.setEnabled(true);
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

        jLabel1 = new javax.swing.JLabel();
        jButtonEditor = new javax.swing.JButton();
        jButtonPrevious = new javax.swing.JButton();
        jButtonNext = new javax.swing.JButton();
        jScrollPane1 = new javax.swing.JScrollPane();
        jTextArea1 = new javax.swing.JTextArea();

        setMinimumSize(new java.awt.Dimension(400, 300));

        jLabel1.setText("Résultats");

        jButtonEditor.setText("Retour en édition");
        jButtonEditor.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonEditorActionPerformed(evt);
            }
        });

        jButtonPrevious.setText("Précédent");
        jButtonPrevious.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonPreviousActionPerformed(evt);
            }
        });

        jButtonNext.setText("Suivant");
        jButtonNext.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonNextActionPerformed(evt);
            }
        });

        jTextArea1.setEditable(false);
        jTextArea1.setColumns(20);
        jTextArea1.setRows(5);
        jTextArea1.setText("Aucun model n'a été trouvé.");
        jScrollPane1.setViewportView(jTextArea1);

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(jScrollPane1)
                    .addGroup(layout.createSequentialGroup()
                        .addComponent(jLabel1)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, 370, Short.MAX_VALUE)
                        .addComponent(jButtonEditor))
                    .addGroup(layout.createSequentialGroup()
                        .addComponent(jButtonPrevious)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(jButtonNext)
                        .addGap(0, 0, Short.MAX_VALUE)))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel1)
                    .addComponent(jButtonEditor))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 310, Short.MAX_VALUE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jButtonPrevious)
                    .addComponent(jButtonNext))
                .addContainerGap())
        );
    }// </editor-fold>//GEN-END:initComponents

    private void jButtonEditorActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonEditorActionPerformed
        switch(getState()) {
            case EDIT_SINGLE :
                // impossible
                break;
            case EDIT_MULTIPLE :
                // impossible
                break;
            case SINGLE_RESULT :
                if(getFrame().getNumberOfFormulas() > 1) {
                    setState(State.EDIT_MULTIPLE);
                    getFrame().setViewToEditor();
                } else {
                    setState(State.EDIT_SINGLE);
                    getFrame().setViewToEditor();
                }
                break;
            case FIRST_RESULT :
                if(getFrame().getNumberOfFormulas() > 1) {
                    setState(State.EDIT_MULTIPLE);
                    getFrame().setViewToEditor();
                } else {
                    setState(State.EDIT_SINGLE);
                    getFrame().setViewToEditor();
                }
                break;
            case INTER_RESULT : 
                if(getFrame().getNumberOfFormulas() > 1) {
                    setState(State.EDIT_MULTIPLE);
                    getFrame().setViewToEditor();
                } else {
                    setState(State.EDIT_SINGLE);
                    getFrame().setViewToEditor();
                }
                break;
            case LAST_RESULT :
                if(getFrame().getNumberOfFormulas() > 1) {
                    setState(State.EDIT_MULTIPLE);
                    getFrame().setViewToEditor();
                } else {
                    setState(State.EDIT_SINGLE);
                    getFrame().setViewToEditor();
                }
                break;
            default : 
                System.out.println("Undefined action set for the state : " + getState());
        }
        getFrame().setViewToEditor();
    }//GEN-LAST:event_jButtonEditorActionPerformed

    private void jButtonPreviousActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonPreviousActionPerformed
        Model m;
        switch(getState()) {
            case EDIT_SINGLE :
                // impossible
                break;
            case EDIT_MULTIPLE :
                // impossible
                break;
            case SINGLE_RESULT :
                // interdit
                break;
            case FIRST_RESULT :
                // interdit
                break;
            case INTER_RESULT :
                /* TODO
                Afficher le model précédent m
                Si m est le premier
                alors on passe à l'état FIRST_RESULT
                sinon à INTER_RESULT
                */
                break;
            case LAST_RESULT :
                /* TODO
                Afficher le model précédent m
                Si m est le premier
                alors on passe à l'état FIRST_RESULT
                sinon à INTER_RESULT
                */
                break;
            default : 
                System.out.println("Undefined action set for the state : " + getState());
        }
    }//GEN-LAST:event_jButtonPreviousActionPerformed

    private void jButtonNextActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonNextActionPerformed
        Model m;
        switch(getState()) {
            case EDIT_SINGLE :
                // impossible
                break;
            case EDIT_MULTIPLE :
                // impossible
                break;
            case SINGLE_RESULT :
                // interdit
                break;
            case FIRST_RESULT :
                /* TODO
                Affiche le model suivant m
                si m est le dernier model de models (la liste des models calculés)
                alors demander au solveur de chercher un autre model
                    si le solveur ne trouve pas, passe en état LAST_RESULT
                    sinon on passe en INTER_RESULT
                */
                break;
            case INTER_RESULT :
                /* TODO
                Affiche le model suivant m
                si m est le dernier model de models (la liste des models calculés)
                alors demander au solveur de chercher un autre model
                    si le solveur ne trouve pas, passe en état LAST_RESULT
                    sinon on passe en INTER_RESULT
                */
                break;
            case LAST_RESULT :
                // interdit
                break;
            default : 
                System.out.println("Undefined action set for the state : " + getState());
        }
    }//GEN-LAST:event_jButtonNextActionPerformed


    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JButton jButtonEditor;
    private javax.swing.JButton jButtonNext;
    private javax.swing.JButton jButtonPrevious;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JTextArea jTextArea1;
    // End of variables declaration//GEN-END:variables
}
