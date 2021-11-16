//
//  SettingsViewController.swift
//  myminermonitor
//
//  Created by Aron Springfield on 16/05/2018.
//  Copyright © 2018 Aron Springfield. All rights reserved.
//

import UIKit

enum SettingsTableViewSectionType: Int {
    case dailyReport
    case minimumMinersWarning
}

class SettingsViewController: UITableViewController {

    @IBOutlet weak var dailyReportSwitch: UISwitch!
    @IBOutlet weak var reportTimeLabel: UILabel!
    @IBOutlet weak var downtimeWarningSwitch: UISwitch!
    @IBOutlet weak var minimumMinersLabel: UILabel!
    @IBOutlet weak var send24HourReportNow: UIButton!
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        if Locale.clockStyle() == .twentyFourHourClock {
            dateFormatter.dateFormat =  "HH:mm"
        } else {
            dateFormatter.dateFormat =  "h:mma"
        }
        return dateFormatter
    }()
    
    var pickerFrame: CGRect {
        get {
            let targetHeight: CGFloat = 216
            let rect = CGRect(x: 0,
                              y: self.view.frame.height - targetHeight,
                              width: self.view.frame.width,
                              height: targetHeight)
            return rect
        }
    }
    lazy var datePicker: UIDatePicker = {
        let dp = UIDatePicker(frame: pickerFrame)
        dp.datePickerMode = .time
        dp.addTarget(self, action: #selector(didChangeDatePickerValue(_:)), for: .valueChanged)
        return dp
    }()
    
    lazy var numberPicker: UIPickerView = {
        let picker = UIPickerView(frame: pickerFrame)
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()
//  TODO: Add the toolbar
//    lazy var toolbar: UIToolbar = {
//        let rect = CGRect(x: 0,
//                          y: 0,
//                          width: self.view.frame.width,
//                          height: 44)
//        let bar = UIToolbar(frame: rect)
//        bar.isTranslucent = true
//        let flexiSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(didPressDoneWithPickerView))
//        bar.setItems([flexiSpace, doneButton], animated: false)
//        bar.isUserInteractionEnabled = true
//        bar.sizeToFit()
//
//        //datePicker.inputAccessoryView = bar
//        return bar
//    }()
    var portfolio: Portfolio?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dailyReportSwitch.isOn = portfolio?.dailyReportsEnabled == true
        downtimeWarningSwitch.isOn = portfolio?.downtimeWarningsEnabled == true
        
        if let reportTime = portfolio?.dailyReportTime {
            reportTimeLabel.text = dateFormatter.string(from: reportTime as Date)
        }
        
        if let minimumMiners = portfolio?.downtimeMinimumMiners {
            minimumMinersLabel.text = String(minimumMiners)
        }
    }
    
    @IBAction func didToggleDailyReports(_ sender: UISwitch) {
        Notifications.shared.onPermissionGranted { (granted) in
            guard granted else {
                sender.isOn = false
                let alert = Notifications.promptUserToEnableNotificationsAlert()
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            self.portfolio?.dailyReportsEnabled = sender.isOn
        }
    }
    
    @IBAction func didToggleDowntimeWarnings(_ sender: UISwitch) {
        Notifications.shared.onPermissionGranted { (granted) in
            guard granted else {
                sender.isOn = false
                let alert = Notifications.promptUserToEnableNotificationsAlert()
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            self.portfolio?.downtimeWarningsEnabled = sender.isOn
            if sender.isOn && self.portfolio?.downtimeMinimumMiners == 0 {
                self.portfolio?.downtimeMinimumMiners = 1 // TODO read from value on screen
            }
        }
    }
    
    @objc func didPressDoneWithPickerView(_ sender: Any?) {
        
    }
    
    @objc func didChangeDatePickerValue(_ picker: UIDatePicker) {
        let dateString = dateFormatter.string(from: picker.date)
        reportTimeLabel.text = dateString
        portfolio?.dailyReportTime = picker.date as NSDate
        try? portfolio?.managedObjectContext?.save() // TODO expand this try
    }
    
    @IBAction func didPressSend24HourReportButton(_ sender: UIButton) {
        self.portfolio?.sendDailyReport()
        let alert = UIAlertController(title: nil, message: "Sent", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let rowType = SettingsTableViewSectionType(rawValue: indexPath.section) else {
            return
        }
        
        switch (rowType, indexPath.row) {
        case (.dailyReport, 1):
            self.numberPicker.removeFromSuperview()
            self.view.addSubview(self.datePicker)
            break
        case (.minimumMinersWarning, 1):
            self.datePicker.removeFromSuperview()
            self.view.addSubview(self.numberPicker)
            break
        default:
            self.datePicker.removeFromSuperview()
            self.numberPicker.removeFromSuperview()
            break
        }
    }
}

extension SettingsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
   
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 99
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        minimumMinersLabel.text = String(row)
        portfolio?.downtimeMinimumMiners = Int32(row)
        try? portfolio?.managedObjectContext?.save()
    }
}
