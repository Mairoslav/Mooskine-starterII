//
//  NotebooksListViewController.swift
//  Mooskine
//
//  Created by Josh Svatek on 2017-05-31.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import CoreData

class NotebooksListViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!

    var notebooks: [Notebook] = []
    
    var dataController: DataController!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "toolbar-cow"))
        navigationItem.rightBarButtonItem = editButtonItem
        
        let fetchRequest: NSFetchRequest<Notebook> = Notebook.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            notebooks = result
            tableView.reloadData()
        }
        
        
        updateEditButtonState()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: - Actions

    @IBAction func addTapped(sender: Any) {
        presentNewNotebookAlert()
    }

    // -------------------------------------------------------------------------
    // MARK: - Editing

    /// `addNotebook(name:)`.
    func presentNewNotebookAlert() {
        let alert = UIAlertController(title: "New Notebook", message: "Enter a name for this notebook", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] action in
            if let name = alert.textFields?.first?.text {
                self?.addNotebook(name: name)
            }
        }
        saveAction.isEnabled = false

        alert.addTextField { textField in
            textField.placeholder = "Name"
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { notif in
                if let text = textField.text, !text.isEmpty {
                    saveAction.isEnabled = true
                } else {
                    saveAction.isEnabled = false
                }
            }
        }

        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
    }

    func addNotebook(name: String) {
        let notebook = Notebook(context: dataController.viewContext)
        notebook.name = name
        notebook.creationDate = Date()
        try? dataController.viewContext.save()
        notebooks.insert(notebook, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        updateEditButtonState()
    }

    func deleteNotebook(at indexPath: IndexPath) {
        let notebookToDelete = notebook(at: indexPath)
        dataController.viewContext.delete(notebookToDelete)
        try? dataController.viewContext.save()
        
        notebooks.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        
        if numberOfNotebooks == 0 {
            setEditing(false, animated: true)
        }
        updateEditButtonState()
    }

    func updateEditButtonState() {
        navigationItem.rightBarButtonItem?.isEnabled = numberOfNotebooks > 0
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    // -------------------------------------------------------------------------
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfNotebooks
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aNotebook = notebook(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: NotebookCell.defaultReuseIdentifier, for: indexPath) as! NotebookCell

        cell.nameLabel.text = aNotebook.name
        if let count = aNotebook.notes?.count {
            let pageString = count /*aNotebook.notes.count*/ == 1 ? "page" : "pages"
            cell.pageCountLabel.text = "\(aNotebook.notes?.count ?? 0) \(pageString)"
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete: deleteNotebook(at: indexPath)
        default: ()
        }
    }

    var numberOfNotebooks: Int { return notebooks.count }

    func notebook(at indexPath: IndexPath) -> Notebook {
        return notebooks[indexPath.row]
    }

    // -------------------------------------------------------------------------
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? NotesListViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                vc.notebook = notebook(at: indexPath)
                // MARK: NotebooksListViewController: pass `dataController`
                // 00:25 Now, over in NotebooksListViewController (move there ...) we can pass the DataController instance in prepare for sender (b.ii).
                // 00:38 Okay, great. So now, we pass both notebook and the CoreDataStack to the NotesList once a notebook is selected (b.iii). Move to 'NotesListViewController.swift' in viewDidLoad()... 
                vc.dataController = dataController
            }
        }
    }
}
