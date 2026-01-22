using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.NetworkInformation;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace VendingMachines.Desktop.Pages
{
    /// <summary>
    /// Логика взаимодействия для Main.xaml
    /// </summary>
    public partial class Main : Page
    {
        public Main()
        {
            InitializeComponent();
            UserNameText.Text = "Автоматов А.А.";
            UserFullText.Text = "Автоматов А.А.";
            UserRoleText.Text = "Администратор";

        }
        private void ProfileButton_Click(object sender, RoutedEventArgs e)
        {
            ProfilePopup.IsOpen = true;
        }

        private void MyProfile_Click(object sender, RoutedEventArgs e)
        {
            //ContentFrame.Navigate(new Pages.MyProfilePage());
        }

        private void MySessions_Click(object sender, RoutedEventArgs e)
        {
            //ContentFrame.Navigate(new Pages.MySessionsPage());
        }

        private void Logout_Click(object sender, RoutedEventArgs e)
        {
            // чистим токен
            AppData.Token = null;

            // возвращаемся на окно авторизации
            this.NavigationService.Navigate(new Pages.Authentication());
        }

        // Навигация (основные)
        //private void Nav_Dashboard(object sender, RoutedEventArgs e)
        //    => ContentFrame.Navigate(new Pages.DashboardPage());

        //private void Nav_Monitor(object sender, RoutedEventArgs e)
        //    => ContentFrame.Navigate(new Pages.MonitorPage());

        // Подменю
        private void ToggleReportsMenu(object sender, RoutedEventArgs e)
            => ReportsMenu.Visibility = ReportsMenu.Visibility == Visibility.Visible ? Visibility.Collapsed : Visibility.Visible;

        private void ToggleInventoryMenu(object sender, RoutedEventArgs e)
            => InventoryMenu.Visibility = InventoryMenu.Visibility == Visibility.Visible ? Visibility.Collapsed : Visibility.Visible;

        private void ToggleAdminMenu(object sender, RoutedEventArgs e)
            => AdminMenu.Visibility = AdminMenu.Visibility == Visibility.Visible ? Visibility.Collapsed : Visibility.Visible;

        // Заглушки для кликов
        private void Nav_Report1(object sender, RoutedEventArgs e) => MessageBox.Show("Report1");
        private void Nav_Report2(object sender, RoutedEventArgs e) => MessageBox.Show("Report2");
        private void Nav_Goods(object sender, RoutedEventArgs e) => MessageBox.Show("Goods");
        private void Nav_Warehouse(object sender, RoutedEventArgs e) => MessageBox.Show("Warehouse");

        //private void Nav_AdminMachines(object sender, RoutedEventArgs e)
        //    => ContentFrame.Navigate(new Pages.AdminMachinesPage());

        private void Nav_AdminCompanies(object sender, RoutedEventArgs e) => MessageBox.Show("Companies");
        private void Nav_AdminUsers(object sender, RoutedEventArgs e) => MessageBox.Show("Users");
        private void Nav_AdminModems(object sender, RoutedEventArgs e) => MessageBox.Show("Modems");
    }
}
