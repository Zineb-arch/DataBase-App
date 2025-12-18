import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.sql.*;

public class HostLinkGUI extends JFrame {

    // Tabbed Pane to hold different screens
    private JTabbedPane tabbedPane;

    public HostLinkGUI() {
        setTitle("HostLink Management System");
        setSize(800, 600);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null); // Center the window
        // Add menu bar for quick DB tests
        setJMenuBar(createMenuBar());

        // Initialize Tabs
        tabbedPane = new JTabbedPane();

        // Add the tabs (screens)
        tabbedPane.addTab("Register Host", createRegisterPanel());
        tabbedPane.addTab("Create Activity", createActivityPanel());
        tabbedPane.addTab("View Activities", createViewPanel());

        add(tabbedPane);
    }

    // --- SCREEN 1: REGISTER HOST ---
    private JPanel createRegisterPanel() {
        JPanel panel = new JPanel(new GridLayout(7, 2, 10, 10));
        panel.setBorder(BorderFactory.createEmptyBorder(20, 50, 20, 50));

        JTextField userField = new JTextField();
        JPasswordField passField = new JPasswordField();
        JTextField emailField = new JTextField();
        JTextField cinField = new JTextField();
        JTextField descField = new JTextField();
        JTextField phoneField = new JTextField();
        JButton registerBtn = new JButton("Register Host");

        panel.add(new JLabel("Username:")); panel.add(userField);
        panel.add(new JLabel("Password:")); panel.add(passField);
        panel.add(new JLabel("Email:")); panel.add(emailField);
        panel.add(new JLabel("CIN:")); panel.add(cinField);
        panel.add(new JLabel("Description:")); panel.add(descField);
        panel.add(new JLabel("Phone:")); panel.add(phoneField);
        panel.add(new JLabel("")); panel.add(registerBtn);

        // Button Action
        registerBtn.addActionListener(e -> {
            String sqlUser = "INSERT INTO UserAccount (username, user_password, user_email, userType) VALUES (?, ?, ?, 'Host') RETURNING User_id";
            String sqlHost = "INSERT INTO Host (host_id, hos_cin, hos_description, hos_tel) VALUES (?, ?, ?, ?)";

            Connection conn = DBConnection.connect();
            if (conn == null) {
                JOptionPane.showMessageDialog(this, "Cannot connect to database. Ensure JDBC driver is on the classpath and the DB server is running.", "DB Error", JOptionPane.ERROR_MESSAGE);
                return;
            }

            try {
                conn.setAutoCommit(false);
                int userId = -1;

                // Insert User
                try (PreparedStatement pst = conn.prepareStatement(sqlUser)) {
                    pst.setString(1, userField.getText());
                    pst.setString(2, new String(passField.getPassword()));
                    pst.setString(3, emailField.getText());
                    ResultSet rs = pst.executeQuery();
                    if (rs.next()) userId = rs.getInt(1);
                }

                // Insert Host
                if (userId != -1) {
                    try (PreparedStatement pst = conn.prepareStatement(sqlHost)) {
                        pst.setInt(1, userId);
                        pst.setString(2, cinField.getText());
                        pst.setString(3, descField.getText());
                        pst.setString(4, phoneField.getText());
                        pst.executeUpdate();
                    }
                    conn.commit();
                    JOptionPane.showMessageDialog(this, "Success! Host ID: " + userId);
                } else {
                    conn.rollback();
                    JOptionPane.showMessageDialog(this, "Failed to create user.", "Error", JOptionPane.ERROR_MESSAGE);
                }
            } catch (SQLException ex) {
                try { if (conn != null) conn.rollback(); } catch (SQLException ignore) {}
                JOptionPane.showMessageDialog(this, "Database Error: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
            } finally {
                try { if (conn != null) conn.close(); } catch (SQLException ignore) {}
            }
        });

        return panel;
    }

    // --- SCREEN 2: CREATE ACTIVITY ---
    private JPanel createActivityPanel() {
        JPanel panel = new JPanel(new GridLayout(6, 2, 10, 10));
        panel.setBorder(BorderFactory.createEmptyBorder(20, 50, 20, 50));

        JTextField hostIdField = new JTextField();
        JTextField titleField = new JTextField();
        JTextField locField = new JTextField();
        JTextField dateField = new JTextField("2025-01-01");
        JTextField capField = new JTextField();
        JButton createBtn = new JButton("Create Activity");

        panel.add(new JLabel("Host ID:")); panel.add(hostIdField);
        panel.add(new JLabel("Title:")); panel.add(titleField);
        panel.add(new JLabel("Location:")); panel.add(locField);
        panel.add(new JLabel("Date (YYYY-MM-DD):")); panel.add(dateField);
        panel.add(new JLabel("Capacity:")); panel.add(capField);
        panel.add(new JLabel("")); panel.add(createBtn);

        createBtn.addActionListener(e -> {
            String sql = "INSERT INTO Activity (host_id, act_title, act_location, act_date, act_capacity, act_available_seats, act_status) VALUES (?, ?, ?, ?, ?, ?, 'Active')";
            Connection conn = DBConnection.connect();
            if (conn == null) {
                JOptionPane.showMessageDialog(this, "Cannot connect to database. Ensure JDBC driver is on the classpath and the DB server is running.", "DB Error", JOptionPane.ERROR_MESSAGE);
                return;
            }
            try (PreparedStatement pst = conn.prepareStatement(sql)) {
                
                pst.setInt(1, Integer.parseInt(hostIdField.getText()));
                pst.setString(2, titleField.getText());
                pst.setString(3, locField.getText());
                pst.setDate(4, java.sql.Date.valueOf(dateField.getText()));
                int cap = Integer.parseInt(capField.getText());
                pst.setInt(5, cap);
                pst.setInt(6, cap); // Available seats = capacity initially

                pst.executeUpdate();
                JOptionPane.showMessageDialog(this, "Activity Created Successfully!");
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this, "Error: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
            } finally {
                try { if (conn != null) conn.close(); } catch (SQLException ignore) {}
            }
        });

        return panel;
    }

    // --- SCREEN 3: VIEW ACTIVITIES ---
    private JPanel createViewPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        JButton refreshBtn = new JButton("Refresh Data");
        
        // Table setup
        String[] columns = {"ID", "Title", "Location", "Date", "Host Name", "Host Email"};
        DefaultTableModel model = new DefaultTableModel(columns, 0);
        JTable table = new JTable(model);
        JScrollPane scrollPane = new JScrollPane(table);

        panel.add(refreshBtn, BorderLayout.NORTH);
        panel.add(scrollPane, BorderLayout.CENTER);

        // Load Data Action
        refreshBtn.addActionListener(e -> {
            model.setRowCount(0); // Clear table
            String sql = "SELECT activity_id, act_title, act_location, act_date, host_name, host_email FROM vw_ActivityDetails";
            
            Connection conn = DBConnection.connect();
            if (conn == null) {
                JOptionPane.showMessageDialog(this, "Cannot connect to database. Ensure JDBC driver is on the classpath and the DB server is running.", "DB Error", JOptionPane.ERROR_MESSAGE);
                return;
            }
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery(sql)) {

                while (rs.next()) {
                    Object[] row = {
                        rs.getInt("activity_id"),
                        rs.getString("act_title"),
                        rs.getString("act_location"),
                        rs.getDate("act_date"),
                        rs.getString("host_name"),
                        rs.getString("host_email")
                    };
                    model.addRow(row);
                }
            } catch (SQLException ex) {
                JOptionPane.showMessageDialog(this, "Error loading data: " + ex.getMessage());
            } finally {
                try { if (conn != null) conn.close(); } catch (SQLException ignore) {}
            }
        });

        return panel;
    }

    private JMenuBar createMenuBar() {
        JMenuBar mb = new JMenuBar();
        JMenu tools = new JMenu("Tools");
        JMenuItem test = new JMenuItem("Test DB Connection");
        test.addActionListener(e -> {
            Connection conn = DBConnection.connect();
            if (conn != null) {
                try { conn.close(); } catch (SQLException ignore) {}
                JOptionPane.showMessageDialog(this, "DB connection successful.");
            } else {
                JOptionPane.showMessageDialog(this, "DB connection failed. Ensure JDBC jar is in lib/ and the DB is running (run-db.bat).", "DB Error", JOptionPane.ERROR_MESSAGE);
            }
        });
        tools.add(test);
        mb.add(tools);
        return mb;
    }

    public static void main(String[] args) {
        // Run the GUI
        SwingUtilities.invokeLater(() -> {
            new HostLinkGUI().setVisible(true);
        });
    }
}