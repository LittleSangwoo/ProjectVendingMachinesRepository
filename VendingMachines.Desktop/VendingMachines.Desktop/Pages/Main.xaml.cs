using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.NetworkInformation;
using System.Text;
using System.Text.Json;
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
using VendingMachines.Desktop.Services;

namespace VendingMachines.Desktop.Pages
{
    /// <summary>
    /// Логика взаимодействия для Main.xaml
    /// </summary>
    public partial class Main : Page
    {
        public string FullName { get; set; } = "";
        public string Role { get; set; } = "";
        public BitmapImage AvatarImage { get; set; }

        public Main()
        {
            InitializeComponent();
            DataContext = this;


            LoadMe(); // грузим /api/auth/me и заполняем UI
        }

        private void LoadMe()
        {
            // Ожидаем, что сервер возвращает:
            // displayName, role, photoBase64 (не обязательно)
            var root = Services.ApiService.Get<JsonDocument>("/api/auth/me").RootElement;

            FullName = root.GetProperty("displayName").GetString() ?? "";
            Role = root.GetProperty("role").GetString() ?? "";


            // Быстрое обновление биндингов без MVVM
            DataContext = null;
            DataContext = this;
        }

        

        private void MyProfile_Click(object sender, RoutedEventArgs e)
        {
            ProfileToggle.IsChecked = false;
            MessageBox.Show("Открыть страницу: Мой профиль");
            // NavigationService?.Navigate(new ProfilePage());
        }

        private void MySessions_Click(object sender, RoutedEventArgs e)
        {
            ProfileToggle.IsChecked = false;
            MessageBox.Show("Открыть страницу: Мои сессии");
            // NavigationService?.Navigate(new SessionsPage());
        }

        private void Logout_Click(object sender, RoutedEventArgs e)
        {
            ProfileToggle.IsChecked = false;

            // очищаем токен
            // 1. Удаляем токен
            AppData.Token = null;
            Services.ApiService.Token = null;

            // 2. Переходим на страницу авторизации
            NavigationService?.Navigate(new Pages.Authentication());

            // 3. (необязательно, но полезно) очистить стек навигации
            NavigationService?.RemoveBackEntry();

            MessageBox.Show("Выход: токен очищен");
            // NavigationService?.Navigate(new LoginPage());
        }
    }
}
