import java.sql.*;
import java.util.Scanner;

public class HostLinkApp {

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        
        System.out.println("--- HostLink Console App ---");
        System.out.println("1. Register as a Host");
        System.out.println("2. Create an Activity (as Host)");
        System.out.println("3. View All Activities");
        System.out.print("Select an option: ");
        
        int choice = scanner.nextInt();
        scanner.nextLine(); // consume newline

        switch (choice) {
            case 1:
                registerHost(scanner);
                break;
            case 2:
                createActivity(scanner);
                break;
            case 3:
                viewActivities();
                break;
            default:
                System.out.println("Invalid option.");
        }
        scanner.close();
    }

    // SCENARIO 1: Register a Host
    // This demonstrates inserting into the Superclass (UserAccount) 
    // and Subclass (Host) simultaneously.
    private static void registerHost(Scanner scanner) {
        System.out.print("Enter Username: ");
        String username = scanner.nextLine();
        System.out.print("Enter Password: ");
        String password = scanner.nextLine();
        System.out.print("Enter Email: ");
        String email = scanner.nextLine();
        System.out.print("Enter CIN: ");
        String cin = scanner.nextLine();
        System.out.print("Enter Description: ");
        String desc = scanner.nextLine();

        String userSql = "INSERT INTO UserAccount (username, user_password, user_email, userType, user_DateOfCreation) VALUES (?, ?, ?, 'Host', CURRENT_DATE) RETURNING User_id";
        String hostSql = "INSERT INTO Host (host_id, hos_cin, hos_description) VALUES (?, ?, ?)";

        try (Connection conn = DBConnection.connect()) {
            conn.setAutoCommit(false); // Start Transaction

            int userId = -1;

            // 1. Insert into Superclass UserAccount
            try (PreparedStatement pstmtUser = conn.prepareStatement(userSql)) {
                pstmtUser.setString(1, username);
                pstmtUser.setString(2, password);
                pstmtUser.setString(3, email);
                
                ResultSet rs = pstmtUser.executeQuery();
                if (rs.next()) {
                    userId = rs.getInt(1);
                }
            }

            // 2. Insert into Subclass Host using the returned User_id
            if (userId != -1) {
                try (PreparedStatement pstmtHost = conn.prepareStatement(hostSql)) {
                    pstmtHost.setInt(1, userId);
                    pstmtHost.setString(2, cin);
                    pstmtHost.setString(3, desc);
                    pstmtHost.executeUpdate();
                }
                
                conn.commit(); // Commit Transaction
                System.out.println("Host Registered Successfully! Your Host ID is: " + userId);
            } else {
                conn.rollback();
                System.out.println("Failed to create UserAccount.");
            }

        } catch (SQLException e) {
            System.out.println("Error registering host: " + e.getMessage());
        }
    }

    // SCENARIO 2: Create an Activity
    private static void createActivity(Scanner scanner) {
        System.out.print("Enter your Host ID: ");
        int hostId = scanner.nextInt();
        scanner.nextLine();
        System.out.print("Enter Activity Title: ");
        String title = scanner.nextLine();
        System.out.print("Enter Location: ");
        String location = scanner.nextLine();
        System.out.print("Enter Capacity: ");
        int capacity = scanner.nextInt();

        String sql = "INSERT INTO Activity (host_id, act_title, act_location, act_capacity, act_status) VALUES (?, ?, ?, ?, 'Active')";

        try (Connection conn = DBConnection.connect();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, hostId);
            pstmt.setString(2, title);
            pstmt.setString(3, location);
            pstmt.setInt(4, capacity);

            int rows = pstmt.executeUpdate();
            if (rows > 0) {
                System.out.println("Activity Created Successfully!");
            }

        } catch (SQLException e) {
            System.out.println("Error creating activity: " + e.getMessage());
        }
    }

    // SCENARIO 3: View Activities (Retrieval)
    private static void viewActivities() {
        String sql = "SELECT a.activity_id, a.act_title, a.act_location, u.username as host_name " +
                     "FROM Activity a " +
                     "JOIN Host h ON a.host_id = h.host_id " +
                     "JOIN UserAccount u ON h.host_id = u.User_id";

        try (Connection conn = DBConnection.connect();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            System.out.println("\n--- Available Activities ---");
            System.out.printf("%-5s %-20s %-20s %-15s%n", "ID", "Title", "Location", "Host");
            System.out.println("----------------------------------------------------------------");
            
            while (rs.next()) {
                System.out.printf("%-5d %-20s %-20s %-15s%n",
                        rs.getInt("activity_id"),
                        rs.getString("act_title"),
                        rs.getString("act_location"),
                        rs.getString("host_name"));
            }

        } catch (SQLException e) {
            System.out.println("Error retrieving activities: " + e.getMessage());
        }
    }
}