import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {
    // Update these values to match your local PostgreSQL setup
    private static final String URL = "jdbc:postgresql://localhost:5432/hostlinkDB";
    private static final String USER = "localhost";
    private static final String PASSWORD = "507729"; // CHANGE THIS

    public static Connection connect() {
        Connection conn = null;
        try {
            conn = DriverManager.getConnection(URL, USER, PASSWORD);
            System.out.println("Connected to the PostgreSQL server successfully.");
        } catch (SQLException e) {
            System.out.println("Connection failure: " + e.getMessage());
        }
        return conn;
    }
}