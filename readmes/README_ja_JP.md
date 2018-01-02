#### 目次

1. [説明 - モジュールの機能とその有益性](#module-description)
2. [セットアップ](#setup)
   * [前提条件](#requirements)
   * [Azure認証情報を取得](#get-azure-credentials)
   * [Azureモジュールのインストール ](#installing-the-azure-module)
3. [使用方法 - 設定オプションと追加機能](#usage)
4. [参考 - モジュールの機能と動作について](#reference)
   * [タイプ](#types)
   * [パラメータ](#parameters)
5. [既知の問題](#known-issues)
6. [制約事項 - OSの互換性など](#limitations)
7. [開発ー問題を報告してサポートを得る](#development)

## 説明

Microsoft Azureはインフラを作成および管理するための強力なAPIをサービスプラットフォームとして公開しています。AzureモジュールによりPuppetコードを使用してこのAPIを推進することができます。これにより、Puppetは仮想マシンを作成、停止、再起動および破棄することができ、生来的には他のリソースを管理できる、つまりコードとしてのインフラ以上を管理できるようになります。

## セットアップ

### 前提条件

*   次のようなRuby Gems([Installing the Azure module](#installing-the-azure-module), 下記参照)
    *   [azure](https://rubygems.org/gems/azure) 0.7.x
    *   [azure_mgmt_storage](https://rubygems.org/gems/azure_mgmt_storage) 0.14.x
    *   [azure_mgmt_compute](https://rubygems.org/gems/azure_mgmt_compute) 0.14.x
    *   [azure_mgmt_resources](https://rubygems.org/gems/azure_mgmt_resources) 0.14.x
    *   [azure_mgmt_network](https://rubygems.org/gems/azure_mgmt_network) 0.14.x
    *   [hocon](https://rubygems.org/gems/hocon) 1.1.x
*   Azure認証情報(詳細は下記参照)。

#### Azure認証情報を取得

このモジュールを使用するには、Azureアカウントが必要です。すでに持っている場合は、このセクションをスキップできます。

[Azureアカウント](https://azure.microsoft.com/en-us/free/)にサインアップします。

[Azure CLI 1.0](https://docs.microsoft.com/en-us/azure/cli-install-nodejs)をインストールします。これはWindowsおよびLinux上で動作する、クロスプラットフォームのnode.jsベースのツールです。Puppetモジュールに証明書を生成するために必要ですが、Azureと情報をやり取りする便利な方法でもあります。この説明はCLI 2.0('az'コマンド）に対する内容が含めていませんがこのモジュールはAPIを利用します。

Azureアカウントで[CLI登録](https://azure.microsoft.com/en-gb/documentation/articles/xplat-cli-connect/)。

コマンドラインに次のコマンドを入力します。

``` shell
azure account download
azure account import <path to your .publishsettings file>
```

アカウントを作成後、次のコマンドを使用してPEM証明書ファイルをエクスポートします。

``` shell
azure account cert export
```

次、`azure account list`コマンドを使用して、登録IDを取得します。

``` shell
$ azure account list
info:    Executing command account list
data:    Name                    Id                                     Tenant Id  Current
data:    ----------------------  -------------------------------------  ---------  -------
data:    Pay-As-You-Go           xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx  undefined  true
info:    account list command OK
```

代わりにResource Manager API を使用するには、Active DirectoryのサービスPrincipalが必要です。Puppet用を作成する簡単な方法は、[pendrica/azure-credentials](https://github.com/pendrica/azure-credentials)です。[puppetモード](https://github.com/pendrica/azure-credentials#puppet-style-output-note--v-displays-the-file-on-screen-after-creation)により、`azure.conf`(下記参照)を作成することができます。または、公式ドキュメント [これの作成および必要な認証情報の取得](https://azure.microsoft.com/en-us/documentation/articles/resource-group-authenticate-service-principal/)に説明があります。

### Azureモジュールのインストール 

`puppet-agent`1.2(Puppet Enterprise 2015.2.0)以降のこのコマンドを使用して、必要なgemをインストールします。

``` shell
/opt/puppetlabs/puppet/bin/gem install retries --no-ri --no-rdoc
/opt/puppetlabs/puppet/bin/gem install azure --version='~>0.7.0' --no-ri --no-rdoc
/opt/puppetlabs/puppet/bin/gem install azure_mgmt_compute --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppetlabs/puppet/bin/gem install azure_mgmt_storage --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppetlabs/puppet/bin/gem install azure_mgmt_resources --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppetlabs/puppet/bin/gem install azure_mgmt_network --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppetlabs/puppet/bin/gem install hocon --version='~>1.1.2' --no-ri --no-rdoc
```

Windowsにインストールするときに、`Start Command Prompt with Puppet` を起動して次を入力します。

``` shell
gem install retries --no-ri --no-rdoc
gem install azure --version="~>0.7.0" --no-ri --no-rdoc
gem install azure_mgmt_compute --version="~>0.14.0" --no-ri --no-rdoc
gem install azure_mgmt_storage --version="~>0.14.0" --no-ri --no-rdoc
gem install azure_mgmt_resources --version="~>0.14.0" --no-ri --no-rdoc
gem install azure_mgmt_network --version="~>0.14.0" --no-ri --no-rdoc
gem install hocon --version="~>1.1.2" --no-ri --no-rdoc
```

1.2(Puppet Enterprise 2015.2.0)より古い`puppet agent` のバージョンでは、 `gem` バイナリへの古いパスを使用します。

``` shell
/opt/puppet/bin/gem install retries --no-ri --no-rdoc
/opt/puppet/bin/gem install azure --version='~>0.7.0' --no-ri --no-rdoc
/opt/puppet/bin/gem install azure_mgmt_compute --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppet/bin/gem install azure_mgmt_storage --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppet/bin/gem install azure_mgmt_resources --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppet/bin/gem install azure_mgmt_network --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppet/bin/gem install hocon --version='~>1.1.2' --no-ri --no-rdoc
```

> **注意:** Azureモジュールが正しく動作するために、上記の例に詳細が示されている正しいバージョンをインストールするAzure gemをピン止めする必要があります。上記の例では、hocon gemバージョンをピン止めして、可能性のある非互換を防いでいます。

次のAzureインストールに固有の環境変数を設定します。

従来のAPIを使用する場合、次の情報を提供します。

``` shell
export AZURE_MANAGEMENT_CERTIFICATE='/path/to/pem/file'
export AZURE_SUBSCRIPTION_ID='your-subscription-id'
```

Windowsコマンドプロンプトで、情報**いずれの値にもクオーテーションなし**を指定します。


``` shell
SET AZURE_MANAGEMENT_CERTIFICATE=C:\Path\To\file.pem
SET AZURE_SUBSCRIPTION_ID=your-subscription-id
```

Resource ManagementのAPIを使用する場合、次の情報を提供します。

``` shell
export AZURE_SUBSCRIPTION_ID='your-subscription-id'
export AZURE_TENANT_ID='your-tenant-id'
export AZURE_CLIENT_ID='your-client-id'
export AZURE_CLIENT_SECRET='your-client-secret'
```

Windowsコマンドプロンプトで、情報**いずれの値にもクオーテーションなし**を指定します。

``` shell
SET AZURE_SUBSCRIPTION_ID=your-subscription-id
SET AZURE_TENANT_ID=your-tenant-id
SET AZURE_CLIENT_ID=your-client-id
SET AZURE_CLIENT_SECRET=your-client-secret
```

Resource Managerおよび従来の仮想マシン**両方**を動作させている場合は、上記すべての認証情報を提供します。

または、[HOCONフォーマット](https://github.com/typesafehub/config)の設定ファイルの情報を提供することもできます。`azure.conf`として関連する[confdir](https://docs.puppetlabs.com/puppet/latest/reference/dirs_confdir.html)に保存します。

* \*nix Systems: `/etc/puppetlabs/puppet`
* Windows: `C:\ProgramData\PuppetLabs\puppet\etc`
* 非rootユーザ：`~/.puppetlabs/etc/puppet`

ファイルフォーマットは下記の通りです。

``` shell
azure: {
  subscription_id: "your-subscription-id"
  management_certificate: "/path/to/pem/file"
}
```

Windows上でこのファイルを作成するときには、JSON-ベースの設定ファイルフォーマット、パスは適切にエスケープする必要があります。

``` shell
azure: {
  subscription_id: "your-subscription-id"
  management_certificate: "C:\\path\\to\\file.pem"
}
```

**Note**: 少なくともhocon 1.1.2がwindowsにインストールされている必要があります。古いバージョンでは、`azure.conf` がバイトオーダーマーク(BOM)なしでUTF-8としてエンコードされるようにします。技術的な詳細については、[HC-82](https://tickets.puppetlabs.com/browse/HC-82), および[HC-83](https://tickets.puppetlabs.com/browse/HC-83)を参照してください。hocon 1.1.2、BOMありまたはなしのUTF-8で開始。 

または、Resource Management APIあり。

``` shell
azure: {
  subscription_id: "your-subscription-id"
  tenant_id: "your-tenant-id"
  client_id: "your-client-id"
  client_secret: "your-client-secret"
}
```

環境変数 **または** 設定ファイルを使用できます。両方が存在する場合、環境変数が使用されます。環境ファイルに一部の設定を載せて、その他の設定を設定ファイルに載せることはできません。

次、モジュールをインストールします。 

``` shell
puppet module install puppetlabs-azure
```

## 使用方法

### Azure VMを作成

AzureにはデプロイメントにClassicとResource Managerの2つのモードがあります。詳細については、 [Azure Resource Manager対従来のデプロイ: デプロイモデルおよびリソースの状態の理解](https://azure.microsoft.com/en-us/documentation/articles/resource-manager-deployment-model/)を参照してください。モジュールは両方のデプロイメントモードでVMの作成をサポートします。

#### Classic

次を使用してAzureの従来の仮想マシンを作成できます。

```puppet
azure_vm_classic { 'virtual-machine-name':
  ensure           => present,
  image            => 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
  location         => 'West US',
  user             => 'username',
  size             => 'Medium',
  private_key_file => '/path/to/private/key',
}
```

#### Resource Manager

次を使用してAzureのResource Managerの仮想マシンを作成できます。

```puppet
azure_vm { 'sample':
  ensure         => present,
  location       => 'eastus',
  image          => 'canonical:ubuntuserver:14.04.2-LTS:latest',
  user           => 'azureuser',
  password       => 'Password_!',
  size           => 'Standard_A0',
  resource_group => 'testresacc01',
}
```

またimageの代わりに、 [仮想マシン拡張](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-extensions-features/)をVMに追加して、[Marketplace製品](https://azure.microsoft.com/en-us/blog/working-with-marketplace-images-on-azure-resource-manager/)からデプロイすることもできます。

```puppet
azure_vm { 'sample':
  ensure         => present,
  location       => 'eastus',
  user           => 'azureuser',
  password       => 'Password_!',
  size           => 'Standard_A0',
  resource_group => 'testresacc01',
  plan           => {
    'name'      => '2016-1',
    'product'   => 'puppet-enterprise',
    'publisher' => 'puppet',
  },
  extensions     => {
    'CustomScriptForLinux' => {
       'auto_upgrade_minor_version' => false,
       'publisher'                  => 'Microsoft.OSTCExtensions',
       'type'                       => 'CustomScriptForLinux',
       'type_handler_version'       => '1.4',
       'settings'                   => {
         'commandToExecute' => 'sh script.sh',
         'fileUris'         => ['https://myAzureStorageAccount.blob.core.windows.net/pathToScript']
       },
     },
  },
}
```

このタイプにはその他の管理できるプロパティがたくさんあります。

```puppet
azure_vm { 'sample':
  location                      => 'eastus',
  image                         => 'canonical:ubuntuserver:14.04.2-LTS:latest',
  user                          => 'azureuser',
  password                      => 'Password',
  size                          => 'Standard_A0',
  resource_group                => 'testresacc01',
  storage_account               => 'teststoracc01',
  storage_account_type          => 'Standard_GRS',
  os_disk_name                  => 'osdisk01',
  os_disk_caching               => 'ReadWrite',
  os_disk_create_option         => 'fromImage',
  os_disk_vhd_container_name    => 'conttest1',
  os_disk_vhd_name              => 'vhdtest1',
  dns_domain_name               => 'mydomain01',
  dns_servers                   => '10.1.1.1.1 10.1.2.4',
  public_ip_allocation_method   => 'Dynamic',
  public_ip_address_name        => 'ip_name_test01pubip',
  virtual_network_name          => 'vnettest01',
  virtual_network_address_space => '10.0.0.0/16',
  subnet_name                   => 'subnet111',
  subnet_address_prefix         => '10.0.2.0/24',
  ip_configuration_name         => 'ip_config_test01',
  private_ip_allocation_method  => 'Dynamic',
  network_interface_name        => 'nicspec01',
  network_security_group_name   => 'My-Network-Security-Group',
  tags                          => { 'department' => 'devops', 'foo' => 'bar' },
  extensions                    => {
    'CustomScriptForLinux' => {
       'auto_upgrade_minor_version' => false,
       'publisher'                  => 'Microsoft.OSTCExtensions',
       'type'                       => 'CustomScriptForLinux',
       'type_handler_version'       => '1.4',
       'settings'                   => {
         'commandToExecute' => 'sh script.sh',
         'fileUris'         => ['https://myAzureStorageAccount.blob.core.windows.net/pathToScript']
       },
     },
  },
}
```

#### プレミアムストレージ

Azureは、_プレミアム_SSDで動作する本稼働クラス環境の機能を強化するVMをサポートしています。次のように、VM作成時にSSDストレージを選択できます(`Premium_LRS`はAzure APIの内部表現)。

```puppet
azure_vm { 'ssd-example':
  ensure               => present,
  location             => 'centralus',
  image                => 'Canonical:UbuntuServer:16.10:latest',
  user                 => 'azureuser',
  password             => 'Password_!',
  size                 => 'Standard_DS1_v2',
  resource_group       => 'puppetvms',
  storage_account_type => 'Premium_LRS',
}

```

`Premium_LRS`を有効にするには、`Standard_DS1_v2`といった、プレミアムストレージを使用できるVMサイズを選択する**必要があります**。レギュラーHDDで動作するVMは、`Standard_LRS`を用いて作成できます。

#### ブート/ゲスト診断

Azureポータルでは、_ブート診断_と_ゲスト診断_を有効にするスイッチを提供しています。どちらのスイッチも、診断データをダンプするにはストレージアカウントへのアクセスが必要です。

どちらを作動させるかで、スイッチの挙動は異なります。

* ブート診断 - ブート診断を書き出すようにVMの`diagnosticsProfile`設定を設定します。必要に応じてAzureポータルの使用を手動で有効にできます。ブート診断はブート時にのみ適用されるので、VMのブートに問題があるときのインタラクティブなデバッグに最も役立ちます。ブート診断は、必要に応じてAzureポータルから有効化できます。
* ゲスト診断 - 診断状況のアウトプットを取り込むように拡張を設定します。この設定は、選択したゲストOSによって_異なる_設定でなければならず、`extensions`パラメータに適切なデータを供給することによって有効になります。

#### 管理ディスク

Azureの_管理ディスク_では、ストレージアカウントを個々のAzure VMと関連付ける必要性がなくなります。`azure_vm`の管理ディスクを使用するには、`managed_disks`パラメータをtrueに設定します。

```puppet
azure_vm { 'managed-disks-example':
  ensure        => present,
  location      => 'centralus',
  image         => 'Canonical:UbuntuServer:16.10:latest',
  user          => 'azureuser',
  password      => 'Password_!',
  managed_disks => true,
}
```

_管理ディスク_の使用時には_vhd_オプションは設定できず、_管理ディスク_の機能で管理します。

#### ネットワークへの接続

次を使用して、Azure Resource Managerの仮想ネットワークを作成できます。

```puppet
azure_virtual_network { 'vnettest01':
  ensure           => present,
  location         => 'eastus',
  address_prefixes => ['10.0.0.0/16'], # Array of IP address prefixes for the VNet
  dns_servers      => [],              # Array of DNS server IP addresses
}
```

ネットワークオブジェクトは、他のネットワークに届かない小規模なDMZにVMが作成されないように指定します。VMを仮想ネットワークに接続するには、`virtual_network_name`、`subnet_name`、`network_security_group_name`パラメータを指定します。これらはすべて、スラッシュを用いて他のリソースグループのリクエストオブジェクトを検索できるようにします。この機能を使用する場合は、`subnet_name`も仮想ネットワークを指定する必要があることに注意してください。

```puppet
azure_vm { 'web01':
  ensure                      => present,
  location                    => 'centralus',
  image                       => 'canonical:ubuntuserver:14.04.2-LTS:latest',
  user                        => 'azureuser',
  password                    => 'Password_!',
  size                        => 'Standard_A0',
  resource_group              => 'webservers-rg',
  virtual_network_name        => 'hq-rg/delivery-vn',
  subnet_name                 => "hq-rg/delivery-vn/web-sn",
  network_security_group_name => "hq-rg/delivery-nsg",
}
```

`azure_vm`で指定された仮想ネットワークパラメータが存在しない場合、VMと同じリソースグループ内に自動作成されます。これは、非パブリックアドレス上で通信相手がすべて同じリソースグループ内にある基本的な環境で役に立ちます。自動作成を行わないようにするには、`virtual_network_address_space`の指定を省略します。

```puppet
azure_vm { 'web01':
  ensure                        => present,
  location                      => 'centralus',
  resource_group                => 'webservers-rg',
  virtual_network_name          => 'vnettest01',
  virtual_network_address_space => '10.0.0.0/16',
  ...
}
```

### VMの一覧表示および管理

このモジュールは`puppet resource`を通してマシンを一覧表示および管理します。

例:　

``` shell
puppet resource azure_vm_classic
```

これはアカウントのマシンについて一部の情報を出力します。

```puppet
azure_vm_classic { 'virtual-machine-name':
  ensure        => 'present',
  cloud_service => 'cloud-service-uptjy',
  deployment    => 'cloud-service-uptjy',
  hostname      => 'garethr',
  image         => 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
  ipaddress     => 'xxx.xx.xxx.xx',
  location      => 'West US',
  media_link    => 'http://xxx.blob.core.windows.net/vhds/disk_2015_08_28_07_49_34_868.vhd',
  os_type       => 'Linux',
  size          => 'Medium',
}
```

同じコマンドをAzure Resource Managerに使用します。

``` shell
puppet resource azure_vm
```

これによりAzure Resource ManagerのVMが一覧表示されます。

```puppet
azure_vm { 'sample':
  location       => 'eastus',
  image          => 'canonical:ubuntuserver:14.04.2-LTS:latest',
  user           => 'azureuser',
  password       => 'Password',
  size           => 'Standard_A0',
  resource_group => 'testresacc01',
}
```

### Azureストレージアカウントの作成

次を使用して[ストレージアカウント](https://azure.microsoft.com/en-us/documentation/articles/storage-create-storage-account/)を作成できます。

```puppet
azure_storage_account { 'myStorageAccount':
  ensure         => present,
  resource_group => 'testresacc01',
  location       => 'eastus',
  account_type   => 'Standard_GRS',
}
```

> **注意:** ストレージアカウントはAzure Resource Manager APIのみで作成されます。

### Azureリソースグループの作成

次を使用して[リソースグループ](https://azure.microsoft.com/en-us/documentation/articles/resource-group-overview/#resource-groups)を作成できます。

```puppet
azure_resource_group { 'testresacc01':
  ensure   => present,
  location => 'eastus',
}
```

> **Note:** リソースグループはAzure Resource Manager APIのみで作成されます。

### Azureテンプレートデプロイの作成

次を使用して[resource template deployment](https://azure.microsoft.com/en-us/documentation/articles/solution-dev-test-environments/)を作成できます。

```puppet
azure_resource_template { 'My-Network-Security-Group':
  ensure         => 'present',
  resource_group => 'security-testing',
  source         => 'https://gallery.azure.com/artifact/20151001/Microsoft.NetworkSecurityGroup.1.0.0/DeploymentTemplates/NetworkSecurityGroup.json',
  params         => {
    'location'                 => 'eastasia',
    'networkSecurityGroupName' => 'testing',
  },
}
```

> **注意:** リソーステンプレートはAzure Resource Manager APIのみでデプロイされます。

## リファレンス

### タイプ

* [`azure_vm_classic`](#type-azure_vm_classic): Microsoft Azure with Classic Service Management APIで仮想マシンを管理します。
* `azure_vm`: Microsoft Azure with Azure Resource Manager APIで仮想マシンを管理します。
* `azure_storage_account`: Azure Resource Manager APIでストレージアカウントを管理します。
* `azure_resource_group`: Azure Resource Manager APIでリソースグループを管理します。
* `azure_resource_template`: Azure Resource Manager APIでリソーステンプレートを管理します。

### パラメータ

**必須**と指定されない限り、パラメータはオプションです。

#### タイプ: azure_vm_classic

##### `ensure`

仮想マシンの基本的な状態を指定します。 

値: 'present'、'running'、stopped'、'absent'。 

値には以下の効果があります。 

* 'present': VMが実行中か停止状態であるようにします。VMが存在しない場合は、新しいものが作成されます。
* 'running': VMが稼動中であるようにします。VMが存在しない場合は、新しいものが作成されます。 
* 'stopped': VMは作成されているものの、実行中ではないようにします。これは実行中のVMをシャットダウンするために使用されると同時に、直ちに実行せずにVMを作成するために使用されます。 
* 'absent': VMがAzureに存在しないようにします。 

デフォルト値: 'present'。　

##### `name`

**必須**。　

仮想マシンの名前。

##### `image` 

仮想マシンの作成に使用するイメージの名前です。VMイメージまたはOSイメージの場合があります。VMイメージを指定すると、 `user`、`password`、および`private_key_file`は使用されません。

##### `location`

**必須**。　

仮想マシンが作成されるロケーションです。使用可能な値の詳細は[Azure地域マニュアル](http://azure.microsoft.com/en-gb/regions/)を参照してください。ロケーションはVMが作成された後読込専用になります。

##### `user`

Linuxゲストに**必須**です。

仮想マシンで作成されるユーザの名前。

##### `password`

仮想マシンの上記ユーザのパスワード。

##### `private_key_file`

Linuxゲストに上記ユーザとしてアクセスするプライベートキーファイルへのパス。

##### `storage_account`

仮想マシンに作成するストレージアカウントの名前。ソースイメージが'user'イメージの場合、ここで提供されるものの代わりに、ユーザイメージのストレージアカウントが使用されます。

値: 3-24文字の文字列で、数字および/または小文字を含みます。

##### `cloud_service`

関連するクラウドサービスの名前。

##### `deployment`

デプロイの名前。

##### `size`

仮想マシンインスタンスのサイズ。

値: [すべてのサイズのリスト](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-size-specs/)については、Azureのマニュアルを参照してください。

##### `affinity_group`

作成されたクラウトサービスおよびストレージアカウントに使用されるアフィニティグループ。アフィニティグループを使用して、パフォーマンスを向上させるために、コンピュータおよびストレージのコロケーションに影響を与えます。

##### `virtual_network`

仮想マシンが接続する既存の仮想ネットワーク。

##### `subnet`

仮想マシンが関連付けられた、指定された仮想ネットワークの既存のサブネット。

##### `availability_set`

仮想マシンの利用可能セット。関連するマシンがルーチンのメンテナンス中にすべて再起動または中止されないようにします。

##### `reserved_ip`

仮想マシンに関連付けられる、予約されているIPの名前。

##### `data_disk_size_gb`

ギガバイトで指定される、この仮想マシンのデータディスクサイズ。ディスクのライフサイクルで、このサイズは増加のみ可能です。この値が設定されていない場合、Puppetはこの仮想マシンのデータディスクに触れません。

##### `purge_disk_on_delete`

VMが削除されたとき、アタッチされたデータディスクが削除されるかどうか。

値: ブール値。

デフォルト値: `false`。

##### `custom_data`

リリースでホストに関連するデータのブロック。Linuxホストでは、cloud-initによってリリースで実行されるスクリプトの可能性があります。このようなLinuxのホストでは、bashで実行される1行のコマンド(たとえば `touch /tmp/some-file`)か、またはcloud-initでサポートされる任意のフォーマットの複数行ファイル(テンプレートからのものなど)である可能性があります。

Windowsイメージ(およびcloud-initなしのLinuxイメージ)は提供されたデータ上で実行または動作するために、独自のメカニズムを提供する必要があります。

##### `endpoints`

仮想マシンに関連付けられるエンドポイントの一覧。エンドポイントを説明するハッシュの配列を提供します。使用可能なキーは次のとおりです。

* `name`: *必須。* エンドポイントの名前。
* `public_port`: *必須。* このエンドポイントにアクセスするパブリックポート。
* `local_port`: *必須。* 仮想マシンがリッスンしている内部ポート。
* `protocol`: *必須。* `TCP`または`UDP`。
* `direct_server_return`: エンドポイントでのダイレクトサーバーリターンを有効化します。
* `load_balancer_name`: エンドポイントをロードバランサセットに追加する場合、ここで名前を指定します。セットがまだ存在しない場合は、自動的に作成されます。
* `load_balancer`: このエンドポイントをロードバランサ設定に追加するプロパティのハッシュ。
  * `port`: *必須。* 仮想マシンがリッスンしている内部ポート。
  * `protocol`: *必須。* 可用性調査に使用するプロトコル。
  * `interval`: 可用性調査の間隔(秒)。
  * `path`: 可用性調査に使用する相対パス。

もっとも頻繁に使用されるエンドポイントは、LinuxではSSHでWindowsではWinRMです。通常、それらは次のような直接パスで設定されます。

``` shell
endpoints => [{
    name        => 'ssh',
    local_port  => 22,
    public_port => 22,
    protocol    => 'TCP',
  },]
```

または

``` shell
endpoints => [{
    name        => 'WinRm-HTTP',
    local_port  => 5985,
    public_port => 5985,
    protocol    => 'TCP',
  },{
    name        => 'PowerShell',
    local_port  => 5986,
    public_port => 5986,
    protocol    => 'TCP',
  },]
```

> **注意:** SSH、WinRm-HTTP、またはPowerShellエンドポイントの１つを手動で設定するには、これらのエンドポイントを文字どおりに使用します。これはリソースの競合を起こさずにAzureのデフォルトを上書きするために必要です。

##### `os_type`

_Read Only_。

仮想マシンのオペレーティングシステムタイプ。

##### `ipaddress`

_Read Only_。

仮想マシンに割り当てられるIPアドレス。

##### `hostname`

_Read Only_。

実行中の仮想マシンのホスト名。

##### `media_link`

_Read Only_。

仮想マシンの基盤となるディスクイメージのへのリンク。

#### タイプ: azure_vnet

##### `ensure`

仮想ネットワークの基本的な状態を指定します。 

値: 'present'、'running'、stopped'、'absent'。 

値には以下の効果があります。 

* 'present': Azure内に仮想ネットワークが存在するようにします。仮想ネットワークが存在しない場合、新規作成されます。
* 'absent': Azure上に仮想ネットワークが存在しないようにします。

デフォルト値: 'present'。　

##### `name`

**必須**。　

仮想ネットワークの名前。名前は最大64文字までです。

##### `location`

**必須**。　

仮想ネットワークを作成するロケーション。仮想ネットワークが作成された後は、ロケーションは読込専用になります。

値: [Azure地域マニュアル](http://azure.microsoft.com/en-gb/regions/)を参照してください。　

##### `resource_group`　

**必須**。　

新しい仮想ネットワークのリソースグループ。

値: [リソースグループ](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/)を参照してください。

##### `dns_servers`

仮想ネットワーク内のVMに与えられるDNSサーバの配列

デフォルト値: [] # なし

##### `address_prefixes`

プレフィックスの詳細は[仮想ネットワーク設定](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx)で利用できます。

デフォルト: ['10.0.0.0/16']

#### タイプ: azure_network_security_group

##### `ensure`

仮想マシンの基本的な状態を指定します。 

値: 'present'、'absent'

値には以下の効果があります。 

* 'present': Azure内にネットワークセキュリティグループが存在するようにします。存在しない場合、新規作成されます。
* 'absent': Azure上にネットワークセキュリティグループが存在しないようにします。

デフォルト値: 'present'。　

##### `name`

**必須**。　

ネットワークセキュリティグループの名前。名前は最大64文字までです。

##### `location`

**必須**。　

仮想ネットワークを作成するロケーション。仮想ネットワークが作成された後は、ロケーションは読込専用になります。

値: [Azure地域マニュアル](http://azure.microsoft.com/en-gb/regions/)を参照してください。　

##### `resource_group`　

**必須**。　

新しい仮想ネットワークのリソースグループ。

値: [リソースグループ](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/)を参照してください。

##### `tags`

ラベルを付けるタグのハッシュ。

例:

```puppet
tags => {'department' => 'devops', 'foo' => 'bar'}
```

#### タイプ: azure_vm

##### `ensure`

仮想マシンの基本的な状態を指定します。 

値: 'present'、'running'、stopped'、'absent'。 

値には以下の効果があります。 

* 'present': VMが実行中か停止状態であるようにします。VMが存在しない場合は、新しいものが作成されます。
* 'running': VMが稼動中であるようにします。VMが存在しない場合は、新しいものが作成されます。 
* 'stopped': VMは作成されているものの、実行中ではないようにします。これは実行中のVMをシャットダウンするために使用されると同時に、直ちに実行せずにVMを作成するために使用されます。 
* 'absent': VMがAzureに存在しないようにします。 

デフォルト値: 'present'。　

##### `name`

**必須**。　

仮想マシンの名前。名前は最大64文字までです。一部のイメージにはより限定的な要件がある場合があります。

##### `image` 

仮想マシンを作成するために使用するイメージの名前。Marketplace `plan`が提供されていない場合**必須**です。

値: ARM image_referenceフォーマットである必要があります。[Azureイメージリファレンス](https://azure.microsoft.com/en-gb/documentation/articles/virtual-machines-deploy-rmtemplates-azure-cli/)を参照してください。

``` shell
canonical:ubuntuserver:14.04.2-LTS:latest
```

##### `location`

**必須**。　

仮想マシンを作成するロケーション。VMが作成された後は、ロケーションは読込専用になります。

値: [Azure地域マニュアル](http://azure.microsoft.com/en-gb/regions/)を参照してください。　

##### `user`

Linuxゲストに**必須**です。

仮想マシンで作成されるユーザの名前。

##### `password`

**必須**。　

仮想マシンのユーザのパスワード

##### `size`

**必須**。　

仮想マシンインスタンスのサイズ。ARMでは"classic"サイズが標準でプレフィックスされている必要があります。たとえば、ARMのA0では、Standard_A0. D-Seriesサイズがすでにプレフィックスされています。

値: [すべてのサイズのリスト](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-size-specs/)については、Azureのマニュアルを参照してください。

##### `resource_group`　

**必須**。　

新しい仮想マシンのリソースグループ。

値: [リソースグループ](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/)を参照してください。

##### `storage_account`

登録IDのストレージアカウント名。

ストレージアカウント名のルールは[ストレージアカウント](https://msdn.microsoft.com/en-us/library/azure/hh264518.aspx)に定義されています。

##### `storage_account_type`

仮想マシンに関連付けられるストレージアカウントのタイプ。

[有効なアカウントタイプ](https://msdn.microsoft.com/en-us/library/azure/mt163564.aspx)を参照してください。
デフォルト: `Standard_GRS`。

##### `os_disk_name`

仮想マシンにアタッチされるディスク名。

##### `os_disk_caching`

アタッチされたディスクのキャッシングタイプ。

[キャッシング](https://azure.microsoft.com/en-gb/documentation/articles/storage-premium-storage-preview-portal/)を参照してください。

デフォルト: `ReadWrite`。

##### `os_disk_create_option`

作成されたオプションは[オプション](https://msdn.microsoft.com/en-us/library/azure/mt163591.aspx)に一覧表示されます。

デフォルト: `FromImage`。

##### `os_disk_vhd_container_name`

vhdコンテナ名は、仮想マシンのvhd uriの作成に使用されます。

これにより、storage_accountおよびos_disk_vhd_nameが入れ替えられて、仮想ハードディスクイメージのURIになります。

``` shell
https://#{storage_account}.blob.core.windows.net/#{os_disk_vhd_container_name}/#{os_disk_vhd_name}.vhd
```

##### `os_disk_vhd_name`

仮想マシンのvhd URIを形成するvhdの名前。

##### `dns_domain_name`

仮想マシンに関連付けられるDNSドメイン名。

##### `dns_servers`

仮想マシン上で設定されるDNSサーバ。

デフォルト: '10.1.1.1 10.1.2.4'

##### `public_ip_allocation_method`

パブリックIPの割当方法。

値: 'Static'、'Dynamic'、'None'。

デフォルト: 'Dynamic'。

##### `public_ip_address_name`

パブリックIPアドレスのキー名。

##### `virtual_network_name`

仮想マシンの仮想ネットワークのキー名。

[仮想ネットワーク設定](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx)参照

##### `virtual_network_address_space`

プライベート仮想ネットワークのIPの範囲。

文字列または文字列の配列。 [仮想ネットワーク設定](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx)を参照してください。

デフォルト: '10.0.0.0/16'。

##### `subnet_name`

仮想ネットワークのプライベートサブネット名。[仮想ネットワーク設定](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx)を参照してください。

##### `subnet_address_prefix`

プレフィックスの詳細は[仮想ネットワーク設定](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx)で利用できます。

デフォルト: '10.0.2.0/24'

##### `ip_configuration_name`

VMのIP設定のキー名。

##### `private_ip_allocation_method`

プライベートIPの割当方法。

値: 'Static'、'Dynamic'。

デフォルト: 'Dynamic'

##### `network_interface_name`

仮想マシンのネットワークインターフェースコントローラ(NIC)名。

##### `custom_data`

リリースでホストに関連するデータのブロック。Linuxホストでは、cloud-initによってリリースで実行されるスクリプトの可能性があります。このようなLinuxのホストでは、bashで実行される1行のコマンド(たとえば `touch /tmp/some-file`)か、またはcloud-initでサポートされる任意のフォーマットの複数行ファイル(テンプレートからのものなど)である可能性があります。

Windowsイメージ(およびcloud-initなしのLinuxイメージ)は提供されたデータ上で実行または動作するために、独自のメカニズムを提供する必要があります。

##### `data_disks`

Azure VMにアタッチされている単一または複数のデータディスクを管理します。このパラメータは、キーがデータディスク名で値がデータディスクプロパティのhashであるhashを要求します。

Azure VM data_disksは次のパラメータをサポートします。

###### `caching`

データディスクのキャッシング動作を指定します。

値:

* 'None'
* 'ReadOnly'
* 'ReadWrite'

デフォルト値は'None'です。

###### `create_option`

ディスクイメージの作成オプションを指定します。

値: 'FromImage'、'Empty'、'Attach'。

###### `data_size_gb`

仮想マシンにアタッチされる空のディスクのサイズをGBで指定します。

###### `lun`

ディスクの論理ユニット番号(LUN)を指定します。LUNは、仮想マシンの使用のためにマウントされたときにデータドライブが表示されるスロットを指定します。

値: 有効なLUNの値、0から31。

###### `vhd`

ディスクのvhdファイルがあるストレージのblobのロケーションを指定します。vhdがある場所のストレージアカウントは、指定された登録と関連付けられる必要があります。

例:

``` shell
http://example.blob.core.windows.net/disks/mydisk.vhd
```

##### `plan`

Azure Software Marketplace製品("plan"と呼ばれる)からVMをデプロイします。`image`が指定されていない場合に必要です。

値は`name`、`product`、および`publisher`の、3つの必須キーがあるハッシュである必要があります。`promotion_code`はオプションの4番目のキーです。

例:

```puppet
plan => {
  'name'      => '2016-1',
  'product'   => 'puppet-enterprise',
  'publisher' => 'puppet',
},
```

##### `tags`

ラベルを付けるタグのハッシュ。

例:

```puppet
tags => {'department' => 'devops', 'foo' => 'bar'}
```

##### `extensions`

VM上で設定される拡張です。Azure VM ExtensionはAzure VM上で他のプログラムが動作するのを補助する動作または機能を実装しています。オプションでこのパラメータを設定して、拡張を含めることができます。

このパラメータは単一のハッシュ(単一拡張)または複数のハッシュ(複数拡張)のどちらかです。拡張パラメータを'absent'に設定するとVMから拡張が削除されます。

例:

```puppet
extensions     => {
  'CustomScriptForLinux' => {
     'auto_upgrade_minor_version' => false,
     'publisher'                  => 'Microsoft.OSTCExtensions',
     'type'                       => 'CustomScriptForLinux',
     'type_handler_version'       => '1.4',
     'settings'                   => {
       'commandToExecute' => 'sh script.sh',
       'fileUris'         => ['https://myAzureStorageAccount.blob.core.windows.net/pathToScript']
     },
   },
},
```

Puppetエージェントを拡張としてWindows VMにインストールするには、次のようにします。

```puppet
extensions     => {
  'PuppetExtension' => {
     'auto_upgrade_minor_version' => true,
     'publisher'                  => 'Puppet',
     'type'                       => 'PuppetAgent',
     'type_handler_version'       => '1.5',
     'protected_settings'                   => {
       'PUPPET_MASTER_SERVER': 'mypuppetmaster.com'
     },
   },
},
```

VM Extensionsの詳細な情報については、[仮想マシンの拡張および機能について](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-extensions-features/)を参照してください。特定の拡張の設定方法については、[Azure Windows VM拡張設定サンプル](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-extensions-configuration-samples/)を参照してください。

Azure VM Extensionsは次のパラメータをサポートします。

###### `publisher`

エクステンションのパブリッシャー名。

###### `type`

エクステンションのタイプ(たとえば、CustomScriptExtension)。

###### `type_handler_version`

使用するエクステンションのバージョン。

###### `settings`

エクステンション固有の設定(たとえば、CommandsToExecute)。

###### `protected_settings`

VMに渡される前に暗号化されたエクステンションに固有の設定。

###### `auto_upgrade_minor_version`

エクステンションが自動的に最新のマイナーバージョンにアップグレードするかどうかを示します。

#### タイプ: azure_storage_account

##### `ensure`

ストレージアカウントの基本的な状態を指定します。

値: 'present'、'absent'

デフォルト値: 'present'。　

##### `name`

**必須**。　

ストレージアカウントの名前です。グローバルに一意である必要があります。

##### `location`

**必須**

ストレージアカウントが作成されるロケーションです。ストレージアカウントが作成された後、ロケーションは読込専用になります。

値: [Azure地域マニュアル](http://azure.microsoft.com/en-gb/regions/)を参照してください。

##### `resource_group`　

**必須**。　

新しいストレージアカウントのリソースグループ。

値: [リソースグループ](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/)を参照してください。

##### `account_type`

ストレージアカウントのタイプ。ストレージアカウントのパフォーマンスレベルとレプリケーションメカニズムを示します。

値: [アカウントタイプの検証](https://msdn.microsoft.com/en-us/library/azure/mt163564.aspx)を参照してください。

デフォルト値: 'Standard_GRS'。

##### `account_kind`

ストレージアカウントの種類。

値: 'Storage'または'BlobStorage'。

デフォルト: 'Storage'。

##### `tags`

ラベルを付けるタグのハッシュ。

例:

```puppet
tags => {'department' => 'devops', 'foo' => 'bar'}
```

#### タイプ: azure_resource_group

##### `ensure`

リソースグループの基本的な状態を指定します。　

値: 'present'、'absent'

デフォルト値: 'present'。　

##### `name`

**必須**。　

リソースグループの名前。

値: 80文字以内で、英数字、ダッシュ、アンダースコア、開き括弧、閉じ括弧、およびピリオドを含みます。名前はピリオドでは終われません。　

##### `location`

**必須**。　

リソースグループが作成されるロケーション。

値: [Azure地域マニュアル](http://azure.microsoft.com/en-gb/regions/)を参照してください。　

##### `tags`
ラベルを付けるタグのハッシュ。

例:

```puppet
tags => {'department' => 'devops', 'foo' => 'bar'}
```

#### タイプ: azure_resource_template

#### `ensure`

リソースグループの基本的な状態を指定します。　

値: 'present'および'absent'。デフォルトは'present'です。

##### `name`

**必須**。　

テンプレートデプロイの名前。

値: 80文字以内で、英数字、ダッシュ、アンダースコア、開き括弧、閉じ括弧、およびピリオドを含みます。名前はピリオドでは終われません。　

##### `resource_group`　

**必須**。　

新しいテンプレートデプロイのリソースグループ。

値: [リソースグループ](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/)を参照してください。

##### `source`

テンプレートのURI。http://またはhttps://の場合があります。

`content`が指定されているときには指定してはいけません。

##### `content`

Azure Resource Templateのテキスト。

`source`が指定されているときには指定してはいけません。

##### `params`

Azure Resource Templateが必要とするパラメータ。`{ 'key_one' => 'value_one', 'key_two' => 'value_two'}`の形式に従います。

このフォーマットはPuppetに固有です。`params_source`が指定されているときには指定してはいけません。

##### `params_source`

Azure Resource Model標準フォーマットにパラメータを含むファイルのURI。

このファイルのフォーマットは`params`属性で許可されるフォーマットとは異なります。`params`が指定されているときには、指定してはいけません。


#### タイプ: azure_vnet

##### `ensure`

仮想ネットワークの基本的な状態を指定します。 

値: 'present'、'absent'

デフォルト値: 'present'。　

##### `name`

**必須**。　

仮想ネットワークの名前。

値: 80文字以内で、英数字、ダッシュ、アンダースコア、開き括弧、閉じ括弧、およびピリオドを含みます。名前はピリオドでは終われません。　

##### `location`

**必須**。　

仮想ネットワークが作成されるロケーション。

値: [Azure地域マニュアル](http://azure.microsoft.com/en-gb/regions/)を参照してください。　

##### `resource_group`　

**必須**。　

仮想ネットワークを関連付けるリソースグループ。

値: [リソースグループ](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/)を参照してください。

##### `tags`
ラベルを付けるタグのハッシュ。

例:

```puppet
tags => {'department' => 'devops', 'foo' => 'bar'}
```

#### タイプ: azure_subnet

##### `ensure`

サブネットの基本的な状態を指定します。

値: 'present'、'absent'

デフォルト値: 'present'。　

##### `name`

**必須**。　

サブネットの名前。

値: 80文字以内で、英数字、ダッシュ、アンダースコア、開き括弧、閉じ括弧、およびピリオドを含みます。名前はピリオドでは終われません。　

##### `location`

**必須**。　

サブネットが作成されるロケーション。

値: [Azure地域マニュアル](http://azure.microsoft.com/en-gb/regions/)を参照してください。　

##### `resource_group`　

**必須**。　

サブネットを関連付けるリソースグループ。

値: [リソースグループ](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/)を参照してください。

##### `virtual_network`

**必須**。　

サブネットを関連付ける仮想ネットワーク。

##### `tags`
ラベルを付けるタグのハッシュ。

例:

```puppet
tags => {'department' => 'devops', 'foo' => 'bar'}
```

## 既知の問題

Azureモジュールが動作するためには、すべての[azure gems](#installing-the-azure-module)が正常にインストールされている必要があります。[nokogiri](http://www.nokogiri.org/tutorials/installing_nokogiri.html)のインストールに失敗すると、gemのインストールに失敗するという既知の問題があります。

## 制約事項

Ruby Azure SDKはnokogiri gemに依存するため、Windows Agentでモジュールを実行することは、Puppet-agent 1.3.0(Puppet Enterprise 2015.3の一部)以降のみでサポートされています。これらのバージョンでは、[Azureモジュールのインストール](#installing-the-azure-module)に記述されている`gem install azure`コマンドを実行すると、正しいバージョンのnokogiriがインストールされます。

## 開発

このモジュールに問題があったり、機能を要求する必要があったりする場合は、[チケットを送信](https://tickets.puppetlabs.com/browse/MODULES/)してください。

本モジュールに問題がある場合は、[サポートにお問い合わせ](https://puppet.com/support-services/customer-support)ください。
