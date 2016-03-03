import urllib2
import os

DOWN_FOLDER = '/data/nwp1/smurray/SMART/data/'

def main():
    """Download latest HMI_nrt fits file from the JSOC fits page.
    """
    link = get_link("http://jsoc.stanford.edu/data/hmi/fits/latest_fits_time")
    download(link)
    exit
    
def get_link(url):
    """Get the url of the latest fits file to download.
    """
    web_file = urllib2.Request(url)
    web_file.add_header('Cache-Control', 'max-age=0')   #so this makes sure the latest version is downloaded
    web_file = urllib2.build_opener().open(web_file)
    link = web_file.read()
    return link.strip()[10::]

def download(url): 
    """Copy the contents of a file from a given URL.
    """
    web_file = urllib2.Request(url)
    web_file.add_header('Cache-Control', 'max-age=0')
    web_file = urllib2.build_opener().open(web_file)
    #folder = "".join([os.path.expanduser('~'), "/data/"])
    file_loc = "".join([DOWN_FOLDER, 'latest.fits'])
    if not os.path.isdir(DOWN_FOLDER):
        os.mkdir(DOWN_FOLDER)
    save_file = open(file_loc, 'w')
    save_file.write(web_file.read())
    web_file.close()
    save_file.close()
    #del folder
    return file_loc


if __name__ == '__main__':
    main()
