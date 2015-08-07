import Foundation


/**
*  @class           NotificationSettingStreamsViewController
*  @brief           This class will simply render the collection of Streams available for a given
*                   NotificationSettings collection.
*                   A Stream represents a possible way in which notifications are communicated.
*                   For instance: Push Notifications / WordPress.com Timeline / Email
*/

public class NotificationSettingStreamsViewController : UITableViewController
{
    // MARK: - View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        setupTableView()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
        tableView.deselectSelectedRowWithAnimation(true)
        WPAnalytics.track(.OpenedNotificationSettingStreams)
    }


    
    // MARK: - Setup Helpers
    private func setupNotifications() {
        // Reload whenever the app becomes active again since Push Settings may have changed in the meantime!
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self,
            selector:   "reloadTable",
            name:       UIApplicationDidBecomeActiveNotification,
            object:     nil)
    }
    
    private func setupTableView() {
        // iPad Top header
        if UIDevice.isPad() {
            tableView.tableHeaderView = UIView(frame: WPTableHeaderPadFrame)
        }
        
        // Empty Back Button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .Plain, target: nil, action: nil)
        
        // Hide the separators, whenever the table is empty
        tableView.tableFooterView = UIView()
        
        // Style!
        WPStyleGuide.configureColorsForView(view, andTableView: tableView)
    }
    
    
    
    // MARK: - Public Helpers
    public func setupWithSettings(settings: NotificationSettings) {
        // Title
        switch settings.channel {
        case let .Blog(blogId):
            title = settings.blog?.blogName ?? settings.channel.description()
        case .Other:
            title = NSLocalizedString("Other Sites", comment: "Other Notifications Streams Title")
        default:
            // Note: WordPress.com is not expected here!
            break
        }
        
        // Structures
        self.settings       = settings
        self.sortedStreams  = settings.streams.sorted { $0.kind.description() > $1.kind.description() }
        
        tableView.reloadData()
    }
    
    public func reloadTable() {
        tableView.reloadData()
    }
    
    
    
    // MARK: - UITableView Delegate Methods
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionCount
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedStreams?.count ?? emptyRowCount
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as? WPTableViewCell
        if cell == nil {
            cell = WPTableViewCell(style: .Value1, reuseIdentifier: reuseIdentifier)
        }
        
        configureCell(cell!, indexPath: indexPath)
        
        return cell!
    }
    
    
    
    // MARK: - UITableView Delegate Methods
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // iOS <8: Display the 'Enable Push Notifications Alert', when needed
        // iOS +8: Go ahead and push the details
        //
        let stream = sortedStreams![indexPath.row]
        
        if isDisabledDeviceStream(stream) && !UIDevice.isOS8() {
            tableView.deselectSelectedRowWithAnimation(true)
            displayPushNotificationsAlert()
            return
        }
        
        let detailsViewController = NotificationSettingDetailsViewController(style: .Grouped)
        detailsViewController.setupWithSettings(settings!, stream: stream)

        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    
    
    // MARK: - Helpers
    private func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        let stream                  = sortedStreams![indexPath.row]
        
        cell.textLabel?.text        = stream.kind.description() ?? String()
        cell.detailTextLabel?.text  = isDisabledDeviceStream(stream) ? NSLocalizedString("Off", comment: "Disabled") : String()
        cell.accessoryType          = .DisclosureIndicator
        
        WPStyleGuide.configureTableViewCell(cell)
    }
    
    
    
    // MARK: - Disabled Push Notifications Helpers
    private func isDisabledDeviceStream(stream: NotificationSettings.Stream) -> Bool {
        return stream.kind == .Device && !NotificationsManager.pushNotificationsEnabledInDeviceSettings()
    }
    
    private func displayPushNotificationsAlert() {
        let title   = NSLocalizedString("Push Notifications have been turned off in iOS Settings",
                                        comment: "Displayed when Push Notifications are disabled (iOS 7)")
        let message = NSLocalizedString("To enable notifications:\n\n" +
                                        "1. Open **iOS Settings**\n" +
                                        "2. Tap **Notifications**\n" +
                                        "3. Select **WordPress**\n" +
                                        "4. Turn on **Allow Notifications**",
                                        comment: "Displayed when Push Notifications are disabled (iOS 7)")
        let button = NSLocalizedString("Dismiss", comment: "Dismiss the AlertView")
        
        let alert = AlertView(title: title, message: message, button: button, completion: nil)
        alert.show()
    }

    
    

    // MARK: - Private Constants
    private let reuseIdentifier = WPTableViewCell.classNameWithoutNamespaces()
    private let emptyRowCount   = 0
    private let sectionCount    = 1

    // MARK: - Private Properties
    private var settings        : NotificationSettings?
    private var sortedStreams   : [NotificationSettings.Stream]?
}
