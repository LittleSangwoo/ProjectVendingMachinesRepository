using System;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http;
using System.Net.NetworkInformation;
using System.Text;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows;
using System.Windows;
using System.Windows.Controls;
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
    /// Логика взаимодействия для Authentication.xaml
    /// </summary>
    public partial class Authentication : Page
    {
        private static readonly HttpClient _http = new HttpClient();
        public Authentication()
        {
            InitializeComponent();
        }

        private void Login_Click(object sender, RoutedEventArgs e)
        {

            var email = EmailBox.Text?.Trim();
            var pass = PassBox.Password?.Trim();

            if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(pass))
            {
                MessageBox.Show("Введите email и пароль.", "ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            try
            {
                // 1) готовим JSON
                var bodyObj = new { email = email, password = pass };
                var json = JsonSerializer.Serialize(bodyObj);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                // 2) отправляем POST на твой API (замени URL на свой)
                var resp = _http.PostAsync("https://localhost:7050/api/auth/login", content).Result;

                if (!resp.IsSuccessStatusCode)
                {
                    MessageBox.Show("Неверный логин или пароль.", "ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
                    return;
                }

                // 3) читаем ответ
                var respJson = resp.Content.ReadAsStringAsync().Result;

                // ожидаем что сервер вернёт что-то типа: { "token": "...." }
                using (JsonDocument doc = JsonDocument.Parse(respJson))
                {
                    JsonElement tokenEl;

                    if (!doc.RootElement.TryGetProperty("accessToken", out tokenEl))
                    {
                        MessageBox.Show(respJson, "Ответ сервера");
                        MessageBox.Show("Сервер не вернул token.", "ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
                        return;
                    }

                    var token = tokenEl.GetString();

                    if (string.IsNullOrWhiteSpace(token))
                    {
                        MessageBox.Show("Token пустой.", "ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
                        return;
                    }

                    AppData.Token = token;
                }

                this.NavigationService.Navigate(new Pages.Main());
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка подключения: " + ex.Message, "ошибка", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void Registration_Click(object sender, RoutedEventArgs e)
        {

        }
    }
}
